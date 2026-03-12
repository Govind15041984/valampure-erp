from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from app.core.database import get_db
from app.core.security import create_access_token, get_current_user
from app.schemas.partner_schema import PartnerCreate, PartnerResponse, PartnerType, PartnerUpdate
from app.schemas.payments_schema import PaymentCreate
from app.services import partner_service
from app.models.partner_model import Partner
from app.models.sales_model import SalesMaster, SalesDetail
from app.models.purchase_model import PurchaseMaster
from app.models.payments_model import Payment

router = APIRouter(tags=["Payments"])

@router.post("", status_code=status.HTTP_201_CREATED)
def create_partner_payment(
    payload: PaymentCreate, 
    db: Session = Depends(get_db), 
    current_user = Depends(get_current_user)
):
    # 1. Map the incoming JSON to your SQL Payment Model
    new_payment = Payment(
        profile_id=current_user.id,
        partner_id=payload.partner_id,
        payment_date=payload.payment_date,
        payment_type=payload.payment_type, # 'PAYMENT' or 'RECEIPT'
        amount=payload.amount,
        payment_mode=payload.payment_mode,
        reference_no=payload.reference_no,
        remarks=payload.remarks
    )
    
    try:
        db.add(new_payment)
        db.commit()
        db.refresh(new_payment)
        return {"message": "Payment recorded successfully", "id": new_payment.id}
    except Exception as e:
        db.rollback()
        print(f"Error saving payment: {e}")
        raise HTTPException(status_code=500, detail="Could not save payment to database")