from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime, timedelta
from sqlalchemy import desc
from sqlalchemy.orm import Session, joinedload
from app.core.database import get_db
from app.core.security import create_access_token, get_current_user
from app.models.partner_model import Partner, PartnerType
from app.schemas.sales_schema import SalesCreate, SalesResponse
from app.services.sales_service import SalesService
from app.models.sales_model import SalesMaster, SalesDetail
from typing import List, Dict, Any


router = APIRouter(tags=["Sales"])

@router.post("/create", response_model=SalesResponse)
async def create_new_invoice(
    sales_data: SalesCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user) # This is a 'Profile' object
):
    try:
        # FIX: Changed from current_user["profile_id"] to current_user.id
        # Based on your get_current_user function, 'current_user' IS the Profile.
        profile_id = current_user.id
        
        new_invoice = await SalesService.create_invoice(
            db=db, 
            profile_id=profile_id, 
            data=sales_data.dict()
        )
        return new_invoice
        
    except Exception as e:
        print(f"Sales Router Error: {str(e)}")
        # If it's already an HTTPException, just re-raise it
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/next-invoice-number")
def get_next_invoice_number(
    db: Session = Depends(get_db), 
    current_user = Depends(get_current_user)
):
    last_invoice = db.query(SalesMaster).filter(
        SalesMaster.profile_id == current_user.id
    ).order_by(SalesMaster.invoice_number.desc()).first()
    
    if not last_invoice:
        return {"next_no": "1"}
    
    # Simple increment logic
    try:
        next_no = int(last_invoice.invoice_number) + 1
        return {"next_no": str(next_no)}
    except ValueError:
        return {"next_no": ""} # Return empty if it's alphanumeric

@router.get("/list")
def get_sales_list(
    db: Session = Depends(get_db),
    current_user: Any = Depends(get_current_user),
    history_mode: bool = False
):
    pid = current_user.id
    thirty_days_ago = datetime.now().date() - timedelta(days=30)

    # 1. Update query to select the Master record AND the Partner Name
    # We join on the partner_id defined in your model
    query = (
        db.query(SalesMaster, Partner.name.label("partner_name"))
        .join(Partner, SalesMaster.partner_id == Partner.id)
        .filter(SalesMaster.profile_id == pid)
    )

    if history_mode:
        query = query.filter(SalesMaster.invoice_date < thirty_days_ago)
    else:
        query = query.filter(SalesMaster.invoice_date >= thirty_days_ago)

    # 2. Order by most recent first
    results = query.order_by(desc(SalesMaster.invoice_date)).all()
    
    # 3. Format the response so 'partner_name' is available at the top level for Flutter
    sales_list = []
    for sale, p_name in results:
        # Convert the SQLAlchemy object to a dictionary
        sale_dict = {column.name: getattr(sale, column.name) for column in sale.__table__.columns}
        # Add the joined partner name
        sale_dict["partner_name"] = p_name 
        sales_list.append(sale_dict)

    return sales_list

@router.get("/detail/{sale_id}")
def get_sale_detail(
    sale_id: UUID, 
    db: Session = Depends(get_db), 
    current_user: Any = Depends(get_current_user) # Using your sample dependency
):
    # 1. Fetch the Master record and join with Details and Partner
    # SECURITY: Added 'profile_id=current_user.id' to ensure data isolation
    sale = db.query(SalesMaster)\
             .options(joinedload(SalesMaster.items))\
             .filter(
                 SalesMaster.id == sale_id,
                 SalesMaster.profile_id == current_user.id # Multi-tenant Lock
             )\
             .first()

    if not sale:
        raise HTTPException(status_code=404, detail="Invoice not found")

    # 2. Map the DB columns to the JSON structure your Flutter screen expects
    return {
        "id": str(sale.id),
        "invoice_no": sale.invoice_number, 
        "invoice_date": sale.invoice_date.strftime("%d-%m-%Y"),
        "partner_name": sale.partner.name if hasattr(sale, 'partner') else "Unknown",
        "taxable_value": float(sale.total_taxable_value), 
        "sgst": float(sale.sgst_amount), 
        "cgst": float(sale.cgst_amount), 
        "igst": float(sale.igst_amount),
        "grand_total": float(sale.grand_total),
        "bill_url": sale.bill_url,
        "items": [
            {
                "description": item.description,
                "size": item.size_mm, 
                "boxes": float(item.box_count) if item.box_count else 0,
                "total_qty": float(item.total_qty),
                "rate": float(item.rate),
                "amount": float(item.line_total) 
            } for item in sale.items
        ]
    }