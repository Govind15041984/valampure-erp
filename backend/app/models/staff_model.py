from sqlalchemy import Column, String, Numeric, Date, Boolean, ForeignKey, Text, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid
from app.core.database import Base

class Employee(Base):
    __tablename__ = "employees"
    __table_args__ = {"schema": "valampure_erp"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), nullable=False)
    name = Column(String(100), nullable=False)
    phone = Column(String(15))
    designation = Column(String(50))
    current_shift_rate = Column(Numeric(10, 2), default=0.00)
    joining_date = Column(Date, server_default=func.current_date())
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Attendance(Base):
    __tablename__ = "attendance"
    __table_args__ = {"schema": "valampure_erp"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), nullable=False)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.employees.id", ondelete="CASCADE"))
    attendance_date = Column(Date, nullable=False)
    shifts_count = Column(Numeric(3, 1), default=1.0) # 0.5, 1.0, 1.5
    rate_at_time = Column(Numeric(10, 2), nullable=False)
    daily_amount = Column(Numeric(10, 2), nullable=False)
    is_overtime = Column(Boolean, default=False)
    remarks = Column(Text)

class StaffTransaction(Base):
    __tablename__ = "staff_transactions"
    __table_args__ = {"schema": "valampure_erp"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), nullable=False)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.employees.id", ondelete="CASCADE"))
    transaction_date = Column(Date, nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    transaction_type = Column(String(20), nullable=False) # ADVANCE, BONUS, SALARY_DEDUCTION
    payment_mode = Column(String(20), default="CASH")
    description = Column(Text)
    
    # --- NEW COLUMNS FOR SETTLEMENT LOGIC ---
    is_settled = Column(Boolean, default=False)
    settlement_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.salary_payments.id", ondelete="SET NULL"), nullable=True)

class SalaryPayment(Base):
    __tablename__ = "salary_payments"
    __table_args__ = {"schema": "valampure_erp"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id = Column(UUID(as_uuid=True), nullable=False)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("valampure_erp.employees.id", ondelete="CASCADE"))
    
    # Period details
    period_start = Column(Date, nullable=False)
    period_end = Column(Date, nullable=False)
    
    # Financials
    total_shifts = Column(Numeric(5, 1), nullable=False)
    gross_salary = Column(Numeric(10, 2), nullable=False)
    advance_deducted = Column(Numeric(10, 2), default=0.00)
    other_deductions = Column(Numeric(10, 2), default=0.00)
    incentives_added = Column(Numeric(10, 2), default=0.00) # --- NEW COLUMN ---
    net_paid = Column(Numeric(10, 2), nullable=False)
    
    # Status & Meta
    payment_status = Column(String(20), default="PAID") # PENDING, PAID
    payment_date = Column(Date, server_default=func.current_date())
    payment_mode = Column(String(20)) # CASH, G-PAY, BANK
    remarks = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())