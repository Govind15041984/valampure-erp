from pydantic import BaseModel, ConfigDict
from uuid import UUID
from datetime import date, datetime
from typing import Optional, List
from decimal import Decimal

# Shared properties
class EmployeeBase(BaseModel):
    name: str
    phone: Optional[str] = None
    designation: Optional[str] = None
    current_shift_rate: Decimal
    is_active: bool = True

class EmployeeCreate(BaseModel):
    profile_id: UUID
    name: str
    phone: Optional[str] = None
    designation: Optional[str] = None # Operator, Helper, etc.
    current_shift_rate: Decimal = Decimal("0.00")
    joining_date: Optional[date] = None

class EmployeeUpdate(EmployeeBase):
    pass

class EmployeeInDB(EmployeeBase):
    id: UUID
    profile_id: UUID
    joining_date: date
    
    model_config = ConfigDict(from_attributes=True)

# Attendance Schema
class AttendanceCreate(BaseModel):
    employee_id: UUID
    profile_id: UUID
    attendance_date: date
    shifts_count: Decimal
    rate_at_time: Decimal
    daily_amount: Decimal
    remarks: Optional[str] = None

class AttendanceResponse(AttendanceCreate):
    id: UUID
    model_config = ConfigDict(from_attributes=True)

class SalaryPaymentCreate(BaseModel):
    profile_id: UUID
    employee_id: UUID
    period_start: date
    period_end: date
    total_shifts: Decimal
    gross_salary: Decimal
    advance_deducted: Decimal = Decimal("0.00")
    other_deductions: Decimal = Decimal("0.00")
    incentives_added: Decimal = Decimal("0.00") 
    net_paid: Decimal
    payment_mode: str = "CASH"
    remarks: Optional[str] = None

class SalaryPaymentResponse(SalaryPaymentCreate):
    id: UUID
    payment_date: date
    payment_status: str
    
    model_config = ConfigDict(from_attributes=True)

class StaffTransactionCreate(BaseModel):
    profile_id: Optional[UUID] = None
    employee_id: UUID
    transaction_date: date
    amount: Decimal
    transaction_type: str  # ADVANCE, BONUS, SALARY_DEDUCTION
    payment_mode: str = "CASH"
    description: Optional[str] = None

class StaffTransactionResponse(StaffTransactionCreate):
    id: UUID
    is_settled: bool
    settlement_id: Optional[UUID] = None
    
    model_config = ConfigDict(from_attributes=True)

class SalaryPreviewResponse(BaseModel):
    employee_id: UUID
    name: str
    total_shifts: Decimal
    gross_salary: Decimal
    unsettled_advance: Decimal  # Sum of all is_settled=False transactions
    suggested_net_pay: Decimal

