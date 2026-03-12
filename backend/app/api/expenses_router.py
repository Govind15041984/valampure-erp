from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import create_access_token, get_current_user
from app.schemas.expenses_schema import ExpenseCreate, ExpenseResponse
from app.services.expenses_service import ExpenseService
from datetime import datetime
from typing import List, Dict, Any

router = APIRouter(tags=["Daily Expenses"])

@router.post("/", response_model=ExpenseResponse)
def add_expense(expense: ExpenseCreate, db: Session = Depends(get_db), current_user: Any = Depends(get_current_user)):
    """Add a new daily expense (Tea, Petrol, etc.)"""
    return ExpenseService.create_expense(db, expense, profile_id=current_user.id)

@router.get("/monthly", response_model=Dict[str, Any])
def get_monthly_report(
    db: Session = Depends(get_db), 
    current_user: Any = Depends(get_current_user)
    ):
    """
    Fetch all expenses for the current month and the running total.
    """
    now = datetime.now()
    
    # We call the service ONCE. 
    # It now returns the total AND the items as a clean dictionary.
    report_data = ExpenseService.get_monthly_expenses(db, now.year, now.month, profile_id=current_user.id)
    
    # We can add the extra fields like month_name here if needed
    report_data.update({
        "month_name": now.strftime("%B"),
        "year": now.year
    })
    
    return report_data

@router.delete("/{expense_id}")
def remove_expense(expense_id: int, db: Session = Depends(get_db), current_user: Any = Depends(get_current_user)):
    """Delete an expense entry by ID"""
    success = ExpenseService.delete_expense(db, expense_id, profile_id=current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Expense entry not found")
    return {"message": "Expense deleted successfully"}