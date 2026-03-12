from sqlalchemy.orm import Session
from decimal import Decimal
from sqlalchemy import text
import uuid
from app.models.sales_model import SalesMaster, SalesDetail
from app.models.inventory_model import FinishedGoodsStock
from app.models.stock_ledger_model import StockLedger
from app.services.minio_service import make_canonical_sales_name, finalize_sales_bill


class SalesService:
    @staticmethod
    async def create_invoice(db: Session, profile_id: str, data: dict, temp_object_name: str = None):
        try:
            # 1. FETCH PARTNER NAME (Needed for MinIO file naming)
            partner_id_val = uuid.UUID(str(data['partner_id']))
            res = db.execute(
                text("SELECT name FROM valampure_erp.partners WHERE id = :id"),
                {"id": partner_id_val}
            ).fetchone()
            
            if not res:
                raise Exception("Customer not found.")
            partner_name = res[0]

            # 2. MINIO HANDLING (Rename temp PDF to professional name)
            final_bill_url = None
            if temp_object_name and temp_object_name.strip():
                canonical_name = make_canonical_sales_name(
                    partner_name=partner_name,
                    inv_no=str(data.get('invoice_number', 'NA')),
                    inv_date=str(data['invoice_date'])
                )
                # Move from temp to permanent sales bucket
                final_bill_url = finalize_sales_bill(temp_object_name, canonical_name)

            # 3. CREATE SALES MASTER RECORD
            # The DB trigger 'trg_after_sales_insert' handles Partner Balance
            master = SalesMaster(
                profile_id=uuid.UUID(str(profile_id)),
                partner_id=partner_id_val,
                invoice_number=data['invoice_number'],
                invoice_date=data['invoice_date'],
                is_gst=data.get('is_gst', True),
                bill_url=final_bill_url, # Now populated with MinIO URL
                total_taxable_value=Decimal(str(data['total_taxable_value'])),
                cgst_amount=Decimal(str(data.get('cgst_amount', 0))),
                sgst_amount=Decimal(str(data.get('sgst_amount', 0))),
                igst_amount=Decimal(str(data.get('igst_amount', 0))),
                round_off=Decimal(str(data.get('round_off', 0))),
                grand_total=Decimal(str(data['grand_total']))
            )
            db.add(master)
            db.flush() # Get master.id for details and ledger

            # 4. CREATE DETAIL RECORDS AND STOCK LEDGER LOGS
            for item in data['items']:
                # A. Create the Detail entry
                detail = SalesDetail(
                    sales_id=master.id,
                    description=item['description'],
                    size_mm=item['size_mm'],
                    hsn_code=item.get('hsn_code'),
                    box_count=item.get('box_count', 0),
                    mts_count=item.get('mts_count', 0),
                    total_qty=Decimal(str(item['total_qty'])),
                    rate=Decimal(str(item['rate'])),
                    line_total=Decimal(str(item['line_total']))
                )
                db.add(detail)

                # --- DEBUG START ---
                print(f"DEBUG: Attempting to match sale description: '{item['description']}'")
                # --- DEBUG END ---

                # B. FETCH CURRENT STOCK (For Running Balance)
                # We match based on size and description as per your finished_goods_stock table
                # FIX: Use .like() on the Model attributes to match them against your item description
                stock_item = db.query(FinishedGoodsStock).filter(
                    FinishedGoodsStock.profile_id == uuid.UUID(str(profile_id)),
                    # Check if the stock size (e.g., '10') exists within the sale description
                    FinishedGoodsStock.size_mm == item['size_mm'],
                    FinishedGoodsStock.description == item['description']
                ).first()

                # C. ADD TO STOCK LEDGER (The Audit Trail)
                if stock_item:
                    print(f"✅ DEBUG: Found Stock Match! ID: {stock_item.id}, Size: {stock_item.size_mm}")
                    # We refresh to get the new total_mts_in_hand after the trigger subtracted the stock
                    db.refresh(stock_item)

                    new_ledger = StockLedger(
                        profile_id=uuid.UUID(str(profile_id)),
                        description=stock_item.description,
                        size_mm=stock_item.size_mm,
                        transaction_type="SALES", # Marks as Outward
                        reference_id=master.id,
                        qty_in=0,
                        qty_out=detail.total_qty,
                        # Balance after subtraction (Trigger handles physical table subtraction)
                        #running_balance=stock_item.total_mts_in_hand - detail.total_qty
                        running_balance=stock_item.total_mts_in_hand - detail.total_qty
                    )
                    db.add(new_ledger)
                else:
                    # --- CRITICAL DEBUG ---
                    print(f"❌ DEBUG: Match FAILED for '{item['description']}'.")
                    # Let's see what IS in the stock table for this profile
                    existing_stocks = db.query(FinishedGoodsStock).filter(
                        FinishedGoodsStock.profile_id == uuid.UUID(str(profile_id))
                    ).all()
                    print(f"DEBUG: Available sizes in stock table: {[s.size_mm for s in existing_stocks]}")
                    # --- END DEBUG ---

            # 5. FINAL COMMIT
            # Database triggers on sales_detail and sales_master will fire here
            db.commit()
            db.refresh(master)
            return master

        except Exception as e:
            db.rollback()
            print(f"ERROR in SalesService: {str(e)}")
            raise e