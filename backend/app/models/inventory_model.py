from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, Numeric, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base
import uuid
from datetime import datetime

class FinishedGoodsStock(Base):
    __tablename__ = "finished_goods_stock"
    __table_args__ = (
        UniqueConstraint('profile_id', 'description', 'size_mm', name='uq_profile_item_size'),
        {"schema": "valampure_erp"}
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.profiles.id"), nullable=False)
    
    description = Column(String, nullable=False) # e.g., "White Elastic"
    size_mm = Column(String, nullable=False)      # e.g., "8.5 MM"
    
    total_boxes_in_hand = Column(Integer, default=0)
    total_mts_in_hand = Column(Numeric, default=0)
    
    last_updated = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)