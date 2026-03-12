from sqlalchemy.orm import Session
from sqlalchemy import text
import uuid
from decimal import Decimal
from app.models.purchase_model import PurchaseMaster, PurchaseDetail
from app.models.partner_model import Partner
from app.services.minio_service import finalize_purchase_bill, make_canonical_purchase_name

class PurchaseService:
    @staticmethod
    async def create_purchase(
        db: Session, 
        profile_id: str, 
        purchase_data: dict, 
        temp_object_name: str = None
    ):
        # 1. Fetch Partner Name RAW (Needed for MinIO file naming)
        partner_id_val = uuid.UUID(str(purchase_data['partner_id']))
        res = db.execute(
            text("SELECT name FROM valampure_erp.partners WHERE id = :id"),
            {"id": partner_id_val}
        ).fetchone()
        
        if not res:
            raise Exception("Supplier not found.")
        partner_name = res[0]

        # 2. MinIO Handling
        final_bill_url = None
        if temp_object_name and temp_object_name.strip():
            canonical_name = make_canonical_purchase_name(
                partner_name=partner_name,
                bill_no=str(purchase_data.get('bill_number', 'NA')),
                bill_date=str(purchase_data['bill_date'])
            )
            final_bill_url = finalize_purchase_bill(temp_object_name, canonical_name)

        # 3. Prepare Amounts
        final_amt = Decimal(str(purchase_data['final_amount']))
        
        try:
            # 4. Create Master Record
            # NOTE: The DB trigger 'trg_after_purchase_insert' will automatically
            # update the partner's current_balance as soon as this is inserted.
            master = PurchaseMaster(
                profile_id=uuid.UUID(str(profile_id)),
                partner_id=partner_id_val,
                bill_number=purchase_data.get('bill_number'),
                bill_date=purchase_data['bill_date'],
                bill_url=final_bill_url,
                is_gst=purchase_data.get('is_gst', False),
                total_sub_total=Decimal(str(purchase_data['total_sub_total'])),
                total_tax_amount=Decimal(str(purchase_data['total_tax_amount'])),
                final_amount=final_amt
            )
            db.add(master)
            db.flush() # Generates master.id for the details

            # 5. Create Detail Records
            for item in purchase_data.get('items', []):
                detail = PurchaseDetail(
                    purchase_id=master.id,
                    category=item['category'],
                    quantity=Decimal(str(item['quantity'])),
                    uom=item['uom'],
                    rate=Decimal(str(item['rate'])),
                    line_total=Decimal(str(item['line_total']))
                )
                db.add(detail)

            # 6. Commit the transaction
            # The trigger fires inside this commit block at the database level.
            db.commit()
            db.refresh(master)
            return master

        except Exception as e:
            db.rollback()
            print(f"ERROR in PurchaseService: {str(e)}")
            raise e