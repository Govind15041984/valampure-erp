from sqlalchemy import Column, String, Boolean, Date, DateTime, Text
from sqlalchemy.dialects.postgresql import UUID
import uuid
import datetime
from app.core.database import Base

class Profile(Base):
    __tablename__ = "profiles"
    __table_args__ = {"schema": "valampure_erp"} # This maps to your specific schema

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    mobile_number = Column(String, unique=True, nullable=False)
    pin_hash = Column(String, nullable=False)
    owner_name = Column(String)
    company_name = Column(String)

    # New Role Field
    role = Column(String, default="OWNER") # OWNER, SUPERVISOR, STAFF
    
    # Tax & Bank Details
    gstin = Column(String)
    address = Column(Text)
    address1 = Column(String)
    state_code = Column(String, default="33")
    area_code = Column(String)
    bank_name = Column(String)
    account_no = Column(String)
    ifsc_code = Column(String)
    logo_url = Column(Text)
    
    # Control Fields
    support_expiry_date = Column(Date, default=datetime.date.today() + datetime.timedelta(days=30))
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)