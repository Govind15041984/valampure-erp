from pydantic import BaseModel
from uuid import UUID
from datetime import date
from typing import List, Optional

class PurchaseDetailSchema(BaseModel):
    category: str
    quantity: float
    uom: str
    rate: float
    line_total: float

class PurchaseCreate(BaseModel):
    partner_id: UUID
    bill_number: Optional[str] = None
    bill_date: date = date.today()
    is_gst: bool = False
    total_sub_total: float
    total_tax_amount: float
    final_amount: float
    items: List[PurchaseDetailSchema]