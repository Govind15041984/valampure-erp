from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.core.security import create_access_token, get_current_user
from app.schemas.manufacturing_entry_schema import (
    ManufacturingEntryCreate, 
    ManufacturingEntryResponse,
    StockStatusResponse
)
from app.services.manufacturing_service import (
    create_manufacturing_log, 
    get_manufacturing_history
)
from app.models.inventory_model import FinishedGoodsStock


router = APIRouter(tags=["Manufacturing"])

# USE: To submit a new daily production log and update stock/ledger.
# WHEN: The staff clicks "Save" on the Mobile Production screen.
@router.post("/log-entry", response_model=ManufacturingEntryResponse, status_code=status.HTTP_201_CREATED)
def log_production(
    data: ManufacturingEntryCreate, 
    db: Session = Depends(get_db), 
    current_user = Depends(get_current_user)
):
    try:
        # Security: Links the production to the logged-in User's Profile ID
        return create_manufacturing_log(db, data, current_user.id)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail=f"Production Log failed: {str(e)}"
        )

# USE: To fetch the history of production entries.
# WHEN: Opening the "Production History" list on Mobile or Laptop.
@router.get("/history", response_model=List[ManufacturingEntryResponse])
def read_history(
    db: Session = Depends(get_db), 
    current_user = Depends(get_current_user)
):
    return get_manufacturing_history(db, current_user.id)

# USE: To get the current "Bank Balance" of all elastic sizes.
# WHEN: The Owner Dashboard loads to show how much 8.5 MM, 10 MM, etc., is in stock.
@router.get("/current-stock", response_model=List[StockStatusResponse])
def get_inventory(
    db: Session = Depends(get_db), 
    current_user = Depends(get_current_user)
):
    # This queries the Snapshot table directly for speed
    return db.query(FinishedGoodsStock).filter(
        FinishedGoodsStock.profile_id == current_user.id
    ).all()