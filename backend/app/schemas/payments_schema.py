from pydantic import BaseModel, condecimal
from uuid import UUID
from datetime import date
from typing import Optional

class PaymentCreate(BaseModel):
    partner_id: UUID
    payment_date: date
    payment_type: str # 'RECEIPT' or 'PAYMENT'
    amount: condecimal(max_digits=15, decimal_places=2)
    payment_mode: str
    reference_no: Optional[str] = None
    remarks: Optional[str] = None

    class Config:
        from_attributes = True