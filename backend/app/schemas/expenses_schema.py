from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional

class ExpenseBase(BaseModel):
    item_name: str
    amount: float
    category: Optional[str] = "General"
    payment_mode: Optional[str] = "CASH"
    remarks: Optional[str] = None
    expense_date: Optional[date] = None

class ExpenseCreate(ExpenseBase):
    pass

class ExpenseResponse(ExpenseBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True