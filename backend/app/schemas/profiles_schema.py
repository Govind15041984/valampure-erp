from pydantic import BaseModel
from typing import Optional
from datetime import date
from uuid import UUID

# 1. Used only for the initial Signup screen
class UserCreate(BaseModel):
    mobile: str
    pin: str
    owner_name: str
    company_name: str
    role: Optional[str] = "OWNER" # Defaults to OWNER for new signups

# 2. Used when he goes to "Settings" to fill in the rest later
class ProfileUpdate(BaseModel):
    gstin: Optional[str] = None
    address: Optional[str] = None
    area_code: Optional[str] = None
    bank_name: Optional[str] = None
    account_no: Optional[str] = None
    ifsc_code: Optional[str] = None
    logo_url: Optional[str] = None

# 3. Used to send data TO the Flutter app (The "Full" view)
class ProfileOut(BaseModel):
    # Identity & Auth
    id: UUID
    mobile_number: str
    owner_name: str
    company_name: str
    role: str
    
    # Business & Tax Details (Needed for Invoice Header)
    gstin: Optional[str] = None
    address: Optional[str] = None
    state_code: Optional[str] = "33"
    area_code: Optional[str] = None
    logo_url: Optional[str] = None
    
    # Banking Details (Needed for Invoice Footer)
    bank_name: Optional[str] = None
    account_no: Optional[str] = None
    ifsc_code: Optional[str] = None
    
    # System Status
    support_expiry_date: date
    is_active: bool

    class Config:
        from_attributes = True

class LoginRequest(BaseModel):
    mobile: str
    pin: str