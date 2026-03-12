from sqlalchemy.orm import Session
from sqlalchemy import extract, func  # <--- CRITICAL: Added these imports
from datetime import datetime
import uuid
from app.models.expenses_model import DailyExpense
from app.schemas.expenses_schema import ExpenseCreate

class ExpenseService:
    @staticmethod
    def create_expense(db: Session, expense_data: ExpenseCreate, profile_id: uuid.UUID):
        # Convert Pydantic schema to SQLAlchemy model
        db_expense = DailyExpense(**expense_data.model_dump())
        
        # Link to the current logged-in user profile
        db_expense.profile_id = profile_id 
        
        # Fallback if date is missing in the request
        if not db_expense.expense_date:
            db_expense.expense_date = datetime.now().date()
            
        db.add(db_expense)
        db.commit()
        db.refresh(db_expense)
        return db_expense

    @staticmethod
    def get_monthly_expenses(db: Session, year: int, month: int, profile_id: uuid.UUID):
        # 1. Fetch the items belonging ONLY to this profile
        expenses_query = db.query(DailyExpense).filter(
            DailyExpense.profile_id == profile_id,
            extract('year', DailyExpense.expense_date) == year,
            extract('month', DailyExpense.expense_date) == month
        ).order_by(DailyExpense.expense_date.desc()).all()

        # 2. Calculate the total sum specifically for this profile
        total_sum = db.query(func.sum(DailyExpense.amount)).filter(
            DailyExpense.profile_id == profile_id,
            extract('year', DailyExpense.expense_date) == year,
            extract('month', DailyExpense.expense_date) == month
        ).scalar() or 0.0

        # 3. Convert SQLAlchemy objects to a JSON-serializable dictionary
        return {
            "total_amount": float(total_sum),
            "items": [
                {
                    "id": item.id,
                    "expense_date": item.expense_date.isoformat(),
                    "item_name": item.item_name,
                    "category": item.category,
                    "amount": float(item.amount),
                    "payment_mode": item.payment_mode,
                    "remarks": item.remarks,
                }
                for item in expenses_query
            ]
        }

    @staticmethod
    def delete_expense(db: Session, expense_id: int, profile_id: uuid.UUID):
        # Security: Only allow deletion if the expense belongs to the profile
        item = db.query(DailyExpense).filter(
            DailyExpense.id == expense_id,
            DailyExpense.profile_id == profile_id
        ).first()
        
        if item:
            db.delete(item)
            db.commit()
            return True
        return False