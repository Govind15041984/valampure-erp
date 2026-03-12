from sqlalchemy import Column, String, Integer, ForeignKey, DateTime, Numeric, UniqueConstraint,Float, Date, Text
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base
import uuid
from datetime import datetime

class DailyExpense(Base):
    __tablename__ = "daily_expenses"
    __table_args__ = {"schema": "valampure_erp"}

    id = Column(Integer, primary_key=True, index=True)
    profile_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.profiles.id"))
    expense_date = Column(Date, default=datetime.now().date)
    item_name = Column(String(150), nullable=False)
    category = Column(String(50), default="General")
    amount = Column(Float, nullable=False)
    payment_mode = Column(String(20), default="CASH")
    remarks = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.now)

