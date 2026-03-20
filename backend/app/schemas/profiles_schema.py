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
    role: Optional[str] = "OWNER"

# 2. UPDATED: Used when updating profile in Settings
class ProfileUpdate(BaseModel):
    # Identity fields (In case they want to change name)
    owner_name: Optional[str] = None
    company_name: Optional[str] = None
    
    # Business & Tax
    gstin: Optional[str] = None
    address: Optional[str] = None      # Full Address
    address1: Optional[str] = None     # Address Header
    state_code: Optional[str] = None
    area_code: Optional[str] = None
    
    # Banking
    bank_name: Optional[str] = None
    account_no: Optional[str] = None
    ifsc_code: Optional[str] = None
    
    # --- LOGO UPLOAD FIELDS ---
    # logo_url: The final permanent URL (usually set by the server)
    logo_url: Optional[str] = None
    # logo_temp_name: The temporary MinIO object name sent by Flutter
    logo_temp_name: Optional[str] = None 

# 3. Used to send data TO the Flutter app (The "Full" view)
class ProfileOut(BaseModel):
    id: UUID
    mobile_number: str
    owner_name: str
    company_name: str
    role: str
    
    # Business & Tax Details
    gstin: Optional[str] = None
    address: Optional[str] = None
    address1: Optional[str] = None
    state_code: Optional[str] = "33"
    area_code: Optional[str] = None
    logo_url: Optional[str] = None
    
    # Banking Details
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