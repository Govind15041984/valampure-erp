from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from sqlalchemy import text, and_, func
from sqlalchemy.sql.functions import coalesce
from typing import List
import logging
import uuid
from uuid import UUID
from datetime import date, datetime
from app.core.database import get_db
from app.core.security import get_current_user
from app.schemas.staff_schema import (
    StaffTransactionCreate, 
    SalaryPaymentCreate,    
    SalaryPreviewResponse   
)
from app.services.staff_service import StaffService
from app.models.staff_model import Employee, Attendance, StaffTransaction, SalaryPayment

# Setup logger to catch background errors
logger = logging.getLogger(__name__)

router = APIRouter(tags=["Staff & Salary"])

@router.post("/create")
async def create_employee(
    employee_data: dict = Body(...), 
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Adds a new employee to the unit."""
    try:
        employee = await StaffService.create_employee(
            db=db, 
            profile_id=current_user.id, 
            employee_data=employee_data
        )
        return {"status": "success", "id": str(employee.id)}
    except Exception as e:
        logger.error(f"Employee creation failed: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/list")
def list_employees( 
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Lists all active employees for the current profile."""
    return db.query(Employee).filter(
        Employee.profile_id == current_user.id, 
        Employee.is_active == True
    ).all()
#-------------------------------------------------------------

# --- 2. ATTENDANCE 

@router.post("/attendance/bulk")
async def post_attendance(
    payload: dict = Body(...), 
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Receives a list of attendance entries from Flutter."""
    try:
        entries = payload.get('entries', [])
        result = await StaffService.post_bulk_attendance(
            db=db, 
            profile_id=current_user.id, 
            entries=entries
        )
        return result
    except Exception as e:
        logger.error(f"Bulk attendance failed: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/attendance")
def get_attendance(
    start_date: str, # Format: YYYY-MM-DD
    end_date: str,   # Format: YYYY-MM-DD
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Fetches attendance records for a specific date range."""
    attendance_records = db.query(Attendance).filter(
        Attendance.profile_id == current_user.id,
        Attendance.attendance_date >= start_date,
        Attendance.attendance_date <= end_date
    ).all()
    return attendance_records

#---------------------------------------------------------------
# --- 3. TRANSACTIONS & ADVANCES ---

@router.post("/transaction")
async def create_staff_transaction(
    tx_data: StaffTransactionCreate, # Using schema for validation
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Records an Advance, Bonus, or Deduction."""
    try:
        tx = await StaffService.create_staff_transaction(
            db=db, 
            profile_id=current_user.id, 
            tx_data=tx_data.model_dump()
        )
        return {"status": "success", "transaction_id": str(tx.id)}
    except Exception as e:
        logger.error(f"Staff transaction failed: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/advance-balance/{employee_id}")
async def get_employee_balance(
    employee_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Returns the current pending (unsettled) advance for a worker."""
    try:
        balance = StaffService.get_advance_balance(db, uuid.UUID(employee_id))
        return {"advance_balance": float(balance)}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

#---------------------------------------------------------------------
# --- 4. SALARY SETTLEMENT & PREVIEW ---

@router.get("/salary-preview")
async def get_salary_preview(
    start_date: date, 
    end_date: date, 
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """NEW: Returns calculated payroll proposal for review before payment."""
    try:
        preview = await StaffService.get_salary_preview(
            db=db, 
            profile_id=current_user.id, 
            start_date=start_date, 
            end_date=end_date
        )
        return preview
    except Exception as e:
        logger.error(f"Salary preview failed: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/salary-settlement")
async def pay_salary(
    salary_data: SalaryPaymentCreate, # Using schema to support incentives_added
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Finalizes weekly pay and handles splitting of advance balances."""
    try:
        payment = await StaffService.create_salary_settlement(
            db=db, 
            profile_id=current_user.id, 
            salary_data=salary_data.model_dump()
        )
        return {
            "status": "success", 
            "message": "Salary payment recorded and debt splitting handled",
            "payment_id": str(payment.id)
        }
    except Exception as e:
        logger.error(f"Salary settlement failed: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/{employee_id}/statement")
def get_employee_statement(employee_id: UUID, db: Session = Depends(get_db)):
    # 1. Verify Employee
    employee = db.query(Employee).filter(Employee.id == employee_id).first()
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")

    # 2. Lifetime Stats for Bonus Calculation
    # Calculated from all historical SalaryPayments
    stats = db.query(
        func.sum(SalaryPayment.gross_salary).label("total_gross"),
        func.sum(SalaryPayment.total_shifts).label("total_shifts"),
        func.sum(SalaryPayment.net_paid).label("total_net_received"),
        func.sum(SalaryPayment.incentives_added).label("total_incentives")
    ).filter(SalaryPayment.employee_id == employee_id).first()

    # 3. Current Advance Debt (Logic: Total Cash Given - Total Salary Cuts)
    # Total advances given to employee
    total_advances = db.query(
        func.sum(coalesce(StaffTransaction.amount, 0))
    ).filter(
        and_(
            StaffTransaction.employee_id == employee_id,
            StaffTransaction.transaction_type == "ADVANCE"
        )
    ).scalar() or 0

    # TOTAL REPAID: Summing advance_deducted from EVERY SalaryPayment row
    total_repaid = db.query(
        func.sum(coalesce(SalaryPayment.advance_deducted, 0))
    ).filter(
        SalaryPayment.employee_id == employee_id
    ).scalar() or 0

    # Final Balanced Debt
    current_debt = float(total_advances) - float(total_repaid)

    # 4. Get Settlement History
    settlements = db.query(SalaryPayment).filter(
        SalaryPayment.employee_id == employee_id
    ).order_by(SalaryPayment.period_end.desc()).all()

    # 5. Get Unsettled/Raw Transactions (Recent Advances)
    recent_advances = db.query(StaffTransaction).filter(
        and_(
            StaffTransaction.employee_id == employee_id,
            StaffTransaction.transaction_type == "ADVANCE",
            #StaffTransaction.is_settled == False
        )
    ).all()

    return {
        "summary": {
            "name": employee.name,
            "designation": employee.designation,
            "joining_date": str(employee.joining_date),
            "lifetime_earnings": float(stats.total_gross or 0),
            "lifetime_shifts": float(stats.total_shifts or 0),
            "current_debt": round(current_debt, 2),
            "bonus_eligible_amount": float(stats.total_gross or 0) # Base for % bonus calculation
        },
        "history": [
            {
                "date": str(s.payment_date),
                "type": "SETTLEMENT",
                "period": f"{s.period_start} to {s.period_end}",
                "shifts": float(s.total_shifts),
                "gross": float(s.gross_salary),
                "deductions": float(s.advance_deducted + s.other_deductions),
                "net": float(s.net_paid),
                "mode": s.payment_mode
            } for s in settlements
        ] + [
            {
                "date": str(a.transaction_date),
                "type": "ADVANCE",
                "period": "N/A",
                "shifts": 0,
                "gross": 0,
                "deductions": 0,
                "net": float(a.amount),
                "mode": a.payment_mode
            } for a in recent_advances
        ]
    }





