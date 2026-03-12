from pydantic import BaseModel, Field, validator
from typing import Optional
from uuid import UUID
from datetime import datetime
from enum import Enum

class PartnerType(str, Enum):
    SUPPLIER = "SUPPLIER"
    BUYER = "BUYER"

class PartnerBase(BaseModel):
    name: str = Field(..., example="Jai Traders")
    partner_type: PartnerType
    mobile_number: Optional[str] = None
    gstin: Optional[str] = Field(None, max_length=15)
    address: Optional[str] = None
    state_code: Optional[str] = Field(None, max_length=2)
    opening_balance: float = 0.0

class PartnerCreate(PartnerBase):
    pass

class PartnerUpdate(BaseModel):
    name: Optional[str] = None
    mobile_number: Optional[str] = None
    gstin: Optional[str] = None
    address: Optional[str] = None
    state_code: Optional[str] = None
    is_active: Optional[bool] = None

class PartnerResponse(PartnerBase):
    id: UUID
    profile_id: UUID
    current_balance: float
    created_at: datetime

    class Config:
        from_attributes = True # Allows Pydantic to read SQLAlchemy models