from pydantic import BaseModel, Field
from uuid import UUID
from datetime import date
from typing import List, Optional
from decimal import Decimal

class SalesDetailBase(BaseModel):
    description: str
    size_mm: str
    hsn_code: Optional[str] = None
    box_count: Optional[int] = 0
    mts_count: Optional[float] = 0
    total_qty: Decimal
    rate: Decimal
    line_total: Decimal

class SalesCreate(BaseModel):
    partner_id: UUID
    invoice_number: str
    invoice_date: date
    is_gst: bool = True
    total_taxable_value: Decimal
    cgst_amount: Decimal = Decimal("0.00")
    sgst_amount: Decimal = Decimal("0.00")
    igst_amount: Decimal = Decimal("0.00")
    round_off: Decimal = Decimal("0.00")
    grand_total: Decimal
    items: List[SalesDetailBase]

class SalesResponse(BaseModel):
    id: UUID
    invoice_number: str
    grand_total: Decimal
    
    class Config:
        from_attributes = True