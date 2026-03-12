from sqlalchemy import Column, String, Boolean, Numeric, Date, ForeignKey, Text, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.core.database import Base
import uuid

class Payment(Base):
    __tablename__ = "payments"
    __table_args__ = {"schema": "valampure_erp"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), nullable=False)
    partner_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.partners.id"), nullable=False)
    
    payment_date = Column(Date, nullable=False, server_default=func.current_date())
    # payment_type: 'RECEIPT' for money from Buyers, 'PAYMENT' for money to Suppliers
    payment_type = Column(String(20), nullable=False) 
    amount = Column(Numeric(15, 2), nullable=False)
    payment_mode = Column(String(50)) # Cash, UPI, Bank Transfer, Cheque
    reference_no = Column(String(100)) # Transaction ID or Cheque Number
    remarks = Column(Text)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())