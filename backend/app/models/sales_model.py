from sqlalchemy import Column, String, Boolean, Numeric, Date, ForeignKey, Text, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import uuid

class SalesMaster(Base):
    __tablename__ = "sales_master"
    __table_args__ = {"schema": "valampure_erp"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), nullable=False)
    partner_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.partners.id"))
    invoice_number = Column(String(50), unique=True, nullable=False)
    invoice_date = Column(Date, nullable=False)
    is_gst = Column(Boolean, default=True)
    total_taxable_value = Column(Numeric(15, 2), nullable=False)
    cgst_amount = Column(Numeric(15, 2), default=0)
    sgst_amount = Column(Numeric(15, 2), default=0)
    igst_amount = Column(Numeric(15, 2), default=0)
    round_off = Column(Numeric(15, 2), default=0)
    grand_total = Column(Numeric(15, 2), nullable=False)
    bill_url = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    items = relationship("SalesDetail", backref="master", cascade="all, delete-orphan")
    partner = relationship("Partner")

class SalesDetail(Base):
    __tablename__ = "sales_detail"
    __table_args__ = {"schema": "valampure_erp"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    sales_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.sales_master.id", ondelete="CASCADE"))
    description = Column(Text, nullable=False)
    size_mm = Column(String)
    hsn_code = Column(String(20))
    box_count = Column(Numeric)
    mts_count = Column(Numeric)
    total_qty = Column(Numeric(15, 2), nullable=False)
    rate = Column(Numeric(15, 2), nullable=False)
    line_total = Column(Numeric(15, 2), nullable=False)