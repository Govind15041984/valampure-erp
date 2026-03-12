from sqlalchemy import Column, String, ForeignKey, DateTime, Numeric
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base
import uuid
from datetime import datetime

class StockLedger(Base):
    __tablename__ = "stock_ledger"
    __table_args__ = {"schema": "valampure_erp"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.profiles.id"), nullable=False)
    transaction_date = Column(DateTime, default=datetime.utcnow)
    
    description = Column(String, nullable=False)
    size_mm = Column(String, nullable=False) # e.g., "8.5 MM"
    
    transaction_type = Column(String, nullable=False) # 'PRODUCTION' or 'SALE'
    reference_id = Column(UUID(as_uuid=True), nullable=True) # ID of the Production Log or Invoice
    
    qty_in = Column(Numeric, default=0)
    qty_out = Column(Numeric, default=0)
    
    # Stores the balance exactly at the moment this entry was made
    running_balance = Column(Numeric, nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)