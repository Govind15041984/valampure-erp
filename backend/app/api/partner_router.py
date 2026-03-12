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

router = APIRouter(tags=["Partners"])

@router.post("/", response_model=PartnerResponse, status_code=status.HTTP_201_CREATED)
def create_new_partner(
    data: PartnerCreate, 
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return partner_service.create_partner(db, data, current_user.id)

@router.get("/{partner_type}", response_model=List[PartnerResponse])
def list_partners(
    partner_type: PartnerType,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return partner_service.get_partners_by_type(db, current_user.id, partner_type)

@router.patch("/{partner_id}", response_model=PartnerResponse)
def update_partner_info(
    partner_id: UUID,
    data: PartnerUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    partner = partner_service.update_partner(db, partner_id, current_user.id, data)
    if not partner:
        raise HTTPException(status_code=404, detail="Partner not found")
    return partner

@router.get("/{partner_id}/ledger")
def get_partner_ledger(partner_id: UUID, db: Session = Depends(get_db), current_user = Depends(get_current_user)):
    partner = db.query(Partner).filter(Partner.id == partner_id).first()
    if not partner:
        raise HTTPException(status_code=404, detail="Partner not found")

    # Start with the Opening Balance from the database
    opening_bal = float(partner.opening_balance or 0.0)
    ledger = []

    # 1. Get Invoices (Sales or Purchases)
    if partner.partner_type == "BUYER":
        sales = db.query(SalesMaster).filter(SalesMaster.partner_id == partner_id).all()
        for s in sales:
            ledger.append({
                "date": s.invoice_date.strftime("%Y-%m-%d"),
                "description": f"Invoice #{s.invoice_number}",
                "debit": float(s.grand_total),
                "credit": 0.0,
                "created_at": s.created_at,
                "is_opening": False
            })
    else:
        purchases = db.query(PurchaseMaster).filter(PurchaseMaster.partner_id == partner_id).all()
        for p in purchases:
            ledger.append({
                "date": p.bill_date.strftime("%Y-%m-%d"),
                "description": f"Bill #{p.bill_number}",
                "debit": 0.0,
                "credit": float(p.final_amount),
                "created_at": p.created_at,
                "is_opening": False
            })

    # 2. Get Payments
    payments = db.query(Payment).filter(Payment.partner_id == partner_id).all()
    for pay in payments:
        is_buyer = partner.partner_type == "BUYER"
        ledger.append({
            "date": pay.payment_date.strftime("%Y-%m-%d"),
            "description": f"Payment ({pay.payment_mode})",
            # If Buyer: Receipt is Credit. If Supplier: Payment is Debit.
            "debit": float(pay.amount) if not is_buyer else 0.0,
            "credit": float(pay.amount) if is_buyer else 0.0,
            "created_at": pay.created_at,
            "is_opening": False
        })

    # 3. Sort by created_at (Oldest to Newest) to calculate running balance correctly
    ledger.sort(key=lambda x: x["created_at"])

    # 4. Calculate Running Balance starting from Opening Balance
    running_bal = opening_bal
    
    # Create the base list for calculation
    final_ledger = []
    for entry in ledger:
        if partner.partner_type == "BUYER":
            running_bal += (entry["debit"] - entry["credit"])
        else:
            running_bal += (entry["credit"] - entry["debit"])
        
        entry["running_balance"] = round(running_bal, 2)
        final_ledger.append(entry)

    # 5. Reverse the list so Latest is at the Top
    final_ledger.reverse()

    # 6. Add Opening Balance row at the very bottom (the end of the list)
    final_ledger.append({
        "date": "---",
        "description": "Opening Balance",
        "debit": 0.0,
        "credit": 0.0,
        "running_balance": round(opening_bal, 2),
        "created_at": None,
        "is_opening": True
    })

    return final_ledger