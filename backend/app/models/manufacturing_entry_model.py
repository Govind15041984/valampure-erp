from sqlalchemy import Column, String, Integer, ForeignKey, Date, DateTime, Numeric
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base
import uuid
from datetime import datetime

class ManufacturingEntry(Base):
    # Matches your exact SQL table name and schema
    __tablename__ = "manufacturing_entry"
    __table_args__ = {"schema": "valampure_erp"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.profiles.id"), nullable=False)
    production_date = Column(Date, default=datetime.utcnow().date())
    
    # Finished Goods Output (Supports manual entries like "8.5 MM")
    description = Column(String, nullable=False)
    size_mm = Column(String, nullable=False) 
    boxes = Column(Integer, nullable=False)
    total_mts = Column(Numeric, nullable=False)
    
    # Raw Material Consumption
    yarn_used_kg = Column(Numeric, default=0)
    rubber_used_kg = Column(Numeric, default=0)
    
    created_at = Column(DateTime, default=datetime.utcnow)