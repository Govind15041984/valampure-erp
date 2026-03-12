from pydantic import BaseModel, Field
from uuid import UUID
from datetime import date, datetime
from typing import Optional, List
from decimal import Decimal

# --- INPUT SCHEMA ---
# USE: What the staff sends from Mobile when they finish a production run.
# WHEN: The "Save" button is clicked.
class ManufacturingEntryCreate(BaseModel):
    description: str = Field(..., example="White Elastic")
    size_mm: str = Field(..., example="8.5 MM")
    boxes: int = Field(..., gt=0)
    total_mts: Decimal = Field(..., gt=0)
    yarn_used_kg: Decimal = Field(default=0)
    rubber_used_kg: Decimal = Field(default=0)
    production_date: Optional[date] = None

# --- OUTPUT SCHEMAS ---

# USE: To show the production history list.
class ManufacturingEntryResponse(ManufacturingEntryCreate):
    id: UUID
    profile_id: UUID
    created_at: datetime
    
    class Config:
        from_attributes = True

# USE: To show the "Current Stock" on the Dashboard.
# WHEN: The Owner opens the app to see how much 8.5 MM is in the godown.
class StockStatusResponse(BaseModel):
    description: str
    size_mm: str
    total_boxes_in_hand: int
    total_mts_in_hand: Decimal
    last_updated: datetime

    class Config:
        from_attributes = True

# USE: To show the "Passbook" view of a specific size.
class LedgerEntryResponse(BaseModel):
    transaction_date: datetime
    transaction_type: str
    qty_in: Decimal
    qty_out: Decimal
    running_balance: Decimal

    class Config:
        from_attributes = True