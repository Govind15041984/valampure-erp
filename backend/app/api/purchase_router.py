from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import get_current_user
from app.services.purchase_service import PurchaseService
import logging

# Setup logger to catch background errors
logger = logging.getLogger(__name__)

router = APIRouter(tags=["Purchases"])

@router.post("/create")
async def create_purchase(
    purchase_data: dict = Body(...), 
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Creates a new purchase record. 
    Matches the JSON sent from the Flutter PurchaseEntryScreen.
    """
    try:
        # Extract the temporary filename if an image was uploaded to MinIO
        temp_name = purchase_data.get('temp_object_name')

        # FIX: Changed current_user.profile_id to current_user.id
        # Based on your logs, the Profile model uses 'id' as the primary key.
        purchase = await PurchaseService.create_purchase(
            db=db, 
            profile_id=current_user.id, 
            purchase_data=purchase_data, 
            temp_object_name=temp_name
        )
        
        return {
            "status": "success",
            "message": "Purchase recorded and balance updated",
            "id": str(purchase.id)
        }
    
    except Exception as e:
        # Rollback the DB session in case of failure to maintain data integrity
        db.rollback()
        
        # Log the actual error to your terminal so you can see it
        logger.error(f"Purchase creation failed: {str(e)}")
        
        # Send the clean error message back to Flutter
        raise HTTPException(status_code=400, detail=str(e))