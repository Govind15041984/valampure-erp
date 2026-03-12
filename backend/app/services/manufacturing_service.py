from sqlalchemy.orm import Session
from app.models.manufacturing_entry_model import ManufacturingEntry
from app.models.inventory_model import FinishedGoodsStock
from app.models.stock_ledger_model import StockLedger
from app.schemas.manufacturing_entry_schema import ManufacturingEntryCreate
from uuid import UUID
from datetime import datetime

# USE: The "Engine" of the production module.
# WHEN: Triggered when staff/owner saves a production run. 
# It ensures the Journal, Balance, and Passbook are updated simultaneously.
def create_manufacturing_log(db: Session, data: ManufacturingEntryCreate, profile_id: UUID):
    try:
        # 1. SET THE DATE
        log_date = data.production_date if data.production_date else datetime.utcnow().date()
        
        # 2. STEP A: CREATE THE PRODUCTION ENTRY (The Proof)
        db_entry = ManufacturingEntry(
            profile_id=profile_id,
            production_date=log_date,
            description=data.description,
            size_mm=data.size_mm,
            boxes=data.boxes,
            total_mts=data.total_mts,
            yarn_used_kg=data.yarn_used_kg,
            rubber_used_kg=data.rubber_used_kg
        )
        db.add(db_entry)
        db.flush() # Temporary save to get db_entry.id for the ledger

        # 3. STEP B: UPDATE FINISHED GOODS STOCK (The Balance)
        # We look for the specific size (e.g., 8.5 MM) for this profile
        stock_item = db.query(FinishedGoodsStock).filter(
            FinishedGoodsStock.profile_id == profile_id,
            FinishedGoodsStock.description == data.description,
            FinishedGoodsStock.size_mm == data.size_mm
        ).first()

        if stock_item:
            # Update existing row
            stock_item.total_boxes_in_hand += data.boxes
            stock_item.total_mts_in_hand += data.total_mts
        else:
            # Create new row if this is the first time producing this size
            stock_item = FinishedGoodsStock(
                profile_id=profile_id,
                description=data.description,
                size_mm=data.size_mm,
                total_boxes_in_hand=data.boxes,
                total_mts_in_hand=data.total_mts
            )
            db.add(stock_item)
        
        db.flush() # Update the stock object in memory to get the new total_mts_in_hand

        # 4. STEP C: ADD TO STOCK LEDGER (The Passbook/Audit Trail)
        new_ledger = StockLedger(
            profile_id=profile_id,
            description=data.description,
            size_mm=data.size_mm,
            transaction_type="PRODUCTION",
            reference_id=db_entry.id,
            qty_in=data.total_mts,
            qty_out=0,
            running_balance=stock_item.total_mts_in_hand # Current balance after this run
        )
        db.add(new_ledger)

        # 5. FINAL COMMIT
        # If any step above failed, the code jumps to 'except' and nothing is saved.
        db.commit()
        db.refresh(db_entry)
        return db_entry

    except Exception as e:
        db.rollback() # Undo everything if there's an error
        raise e

# USE: Fetches the history of production for the dashboard.
# WHEN: Called whenever the Owner or Staff opens the "Manufacturing History" screen.
def get_manufacturing_history(db: Session, profile_id: UUID, limit: int = 50):
    return db.query(ManufacturingEntry).filter(
        ManufacturingEntry.profile_id == profile_id
    ).order_by(ManufacturingEntry.production_date.desc()).limit(limit).all()