from sqlalchemy import Column, String, Boolean, Numeric, Date, ForeignKey, Text, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
from app.core.database import Base

class PurchaseMaster(Base):
    __tablename__ = "purchase_master"
    __table_args__ = {"schema": "valampure_erp"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), nullable=False)
    partner_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.partners.id"))
    
    bill_number = Column(String(50))
    bill_date = Column(Date)
    bill_url = Column(Text)
    is_gst = Column(Boolean, default=False)
    
    total_sub_total = Column(Numeric(15, 2))
    total_tax_amount = Column(Numeric(15, 2))
    final_amount = Column(Numeric(15, 2), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    items = relationship("PurchaseDetail", back_populates="master", cascade="all, delete-orphan")

class PurchaseDetail(Base):
    __tablename__ = "purchase_details"
    __table_args__ = {"schema": "valampure_erp"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    purchase_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.purchase_master.id"))
    
    category = Column(String(50))
    quantity = Column(Numeric(15, 2))
    uom = Column(String(10))
    rate = Column(Numeric(15, 2))
    line_total = Column(Numeric(15, 2))

    master = relationship("PurchaseMaster", back_populates="items")