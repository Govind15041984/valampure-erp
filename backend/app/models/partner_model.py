import enum
from sqlalchemy import Column, String, Enum as SqlEnum, Numeric, ForeignKey, Text, Boolean, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid
from app.core.database import Base

class PartnerType(str, enum.Enum):
    SUPPLIER = "SUPPLIER"
    BUYER = "BUYER"

class Partner(Base):
    __tablename__ = "partners"
    __table_args__ = {"schema": "valampure_erp"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.profiles.id", ondelete="CASCADE"), nullable=False)
    
    # Identity
    name = Column(String(255), nullable=False)
    partner_type = Column(SqlEnum(PartnerType), nullable=False)
    mobile_number = Column(String(15), nullable=True)
    gstin = Column(String(15), nullable=True)
    address = Column(Text, nullable=True)
    state_code = Column(String(2), nullable=True) # e.g., '33'
    
    # Financials
    opening_balance = Column(Numeric(15, 2), default=0.00)
    current_balance = Column(Numeric(15, 2), default=0.00)
    
    # Status & Timing
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())