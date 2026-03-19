from sqlalchemy.orm import Session
from sqlalchemy import text, and_, func
import uuid
from uuid import UUID
from decimal import Decimal
from datetime import date, datetime
from typing import List
from app.models.staff_model import Employee, Attendance, StaffTransaction, SalaryPayment

class StaffService:
    @staticmethod
    async def create_employee(db: Session, profile_id: str, employee_data: dict):
        try:
            db_employee = Employee(
                profile_id=uuid.UUID(str(profile_id)),
                name=employee_data['name'],
                phone=employee_data.get('phone'),
                designation=employee_data.get('designation'),
                current_shift_rate=Decimal(str(employee_data.get('current_shift_rate', 0))),
                joining_date=employee_data.get('joining_date', date.today()),
                is_active=True
            )
            db.add(db_employee)
            db.commit()
            db.refresh(db_employee)
            return db_employee
        except Exception as e:
            db.rollback()
            raise e

    @staticmethod
    async def post_bulk_attendance(db: Session, profile_id: str, entries: list):
        try:
            p_uuid = UUID(str(profile_id))
            results = {"updated": 0, "inserted": 0, "errors": []}
            
            for entry in entries:
                emp_uuid = UUID(entry['employee_id'])
                att_date = datetime.strptime(entry['attendance_date'], '%Y-%m-%d').date()

                # DEBUG: Let's see if the profile_id actually exists for this employee
                # If the profile_id doesn't match the one in the employees table,
                # your filter will return nothing for updates, and inserts might fail FK checks.
                
                existing_record = db.query(Attendance).filter(
                    Attendance.profile_id == p_uuid,
                    Attendance.employee_id == emp_uuid,
                    Attendance.attendance_date == att_date
                ).first()

                is_ot = float(entry['shifts_count']) > 1.0

                if existing_record:
                    existing_record.shifts_count = entry['shifts_count']
                    existing_record.daily_amount = entry['daily_amount']
                    existing_record.rate_at_time = entry['rate_at_time']
                    existing_record.is_overtime = is_ot
                    results["updated"] += 1
                else:
                    new_attendance = Attendance(
                        profile_id=p_uuid,
                        employee_id=emp_uuid,
                        attendance_date=att_date,
                        shifts_count=entry['shifts_count'],
                        rate_at_time=entry['rate_at_time'],
                        daily_amount=entry['daily_amount'],
                        is_overtime=is_ot
                    )
                    db.add(new_attendance)
                    results["inserted"] += 1
            
            db.commit()
            # This will tell Flutter exactly how many rows were actually handled
            return {"status": "success", "message": f"Updated: {results['updated']}, Inserted: {results['inserted']}"}
            
        except Exception as e:
            db.rollback()
            # Crucial: return the error so Flutter catch block sees it
            raise HTTPException(status_code=400, detail=f"DB Error: {str(e)}")

    @staticmethod
    async def create_staff_transaction(db: Session, profile_id: str, tx_data: dict):
        try:
            transaction = StaffTransaction(
                profile_id=uuid.UUID(str(profile_id)),
                employee_id=uuid.UUID(str(tx_data['employee_id'])),
                transaction_date=tx_data.get('transaction_date', date.today()),
                amount=Decimal(str(tx_data['amount'])),
                transaction_type=tx_data['transaction_type'], 
                payment_mode=tx_data.get('payment_mode', 'CASH'),
                description=tx_data.get('description'),
                is_settled=False # New transactions are always unsettled
            )
            db.add(transaction)
            db.commit()
            db.refresh(transaction)
            return transaction
        except Exception as e:
            db.rollback()
            raise e

    @staticmethod
    async def create_salary_settlement(db, profile_id, salary_data):
        """
        Finalizes the weekly payment. 
        It creates the salary record and marks advances as settled.
        """
        # 1. Create the main Salary Payment record
        payment = SalaryPayment(
            profile_id=profile_id,
            employee_id=salary_data['employee_id'],
            period_start=salary_data['period_start'],
            period_end=salary_data['period_end'],
            total_shifts=salary_data['total_shifts'],
            gross_salary=salary_data['gross_salary'],
            advance_deducted=salary_data['advance_deducted'],
            other_deductions=salary_data['other_deductions'],
            incentives_added=salary_data['incentives_added'],
            net_paid=salary_data['net_paid'],
            payment_mode=salary_data.get('payment_mode', 'CASH'),
            remarks=salary_data.get('remarks')
        )
        db.add(payment)

        # 2. HANDLE ADVANCES (The "Carry Forward" Logic)
        deduction_remaining = Decimal(str(salary_data['advance_deducted']))

        if deduction_remaining > 0:
            # Fetch all unsettled advances for this worker, oldest first
            unsettled_txs = db.query(StaffTransaction).filter(
                StaffTransaction.employee_id == salary_data['employee_id'],
                StaffTransaction.transaction_type == "ADVANCE",
                StaffTransaction.is_settled == False
            ).order_by(StaffTransaction.transaction_date.asc()).all()

            for tx in unsettled_txs:
                if deduction_remaining <= 0:
                    break
                
                if tx.amount <= deduction_remaining:
                    # This advance is fully covered by the deduction
                    deduction_remaining -= tx.amount
                    tx.is_settled = True
                    tx.settled_at = payment.period_end
                else:
                    # Only part of this advance is covered
                    # We split the transaction: mark this one settled, 
                    # and create a new one for the 'Carry Forward' balance
                    remaining_balance = tx.amount - deduction_remaining
                    
                    tx.amount = deduction_remaining # Mark what was actually paid
                    tx.is_settled = True
                    tx.settled_at = payment.period_end
                    tx.description = f"{tx.description} (Partial Settle)"

                    # Create the new 'Carry Forward' transaction
                    carry_forward = StaffTransaction(
                        profile_id=profile_id,
                        employee_id=tx.employee_id,
                        transaction_date=tx.transaction_date,
                        amount=remaining_balance,
                        transaction_type="ADVANCE",
                        is_settled=False,
                        description=f"Balance from {tx.transaction_date}"
                    )
                    db.add(carry_forward)
                    deduction_remaining = 0

        db.commit()
        db.refresh(payment)
        return payment

    @staticmethod
    def get_advance_balance(db: Session, employee_id: uuid.UUID) -> Decimal:
        """Simply sums all unsettled advances."""
        res = db.query(func.sum(StaffTransaction.amount)).filter(
            StaffTransaction.employee_id == employee_id,
            StaffTransaction.transaction_type == 'ADVANCE',
            StaffTransaction.is_settled == False
        ).scalar()
        
        return Decimal(str(res or 0))

    @staticmethod
    async def get_salary_preview(db: Session, profile_id: uuid.UUID, start_date: date, end_date: date):
        """
        Calculates payroll preview. If already settled, returns historical data.
        If not settled, calculates live data from attendance and advances.
        """
        # 1. Get all active employees for this profile
        employees = db.query(Employee).filter(
            Employee.profile_id == profile_id, 
            Employee.is_active == True
        ).all()

        preview_list = []

        for emp in employees:
            # 2. Check if a payment record already exists for this exact week/period
            payment_record = db.query(SalaryPayment).filter(
                SalaryPayment.employee_id == emp.id,
                SalaryPayment.period_start == start_date,
                SalaryPayment.period_end == end_date
            ).first()

            if payment_record:
                # --- CASE A: Already Settled (Historical Data) ---
                total_shifts = payment_record.total_shifts
                gross_salary = payment_record.gross_salary
                advance_deducted = payment_record.advance_deducted
                is_settled = True
            else:
                # --- CASE B: Not Settled (Live Calculation) ---
                # Calculate Shifts from Attendance records in the date range
                attendance_records = db.query(Attendance).filter(
                    Attendance.profile_id == profile_id,
                    Attendance.employee_id == emp.id,
                    Attendance.attendance_date >= start_date,
                    Attendance.attendance_date <= end_date
                ).all()

                total_shifts = sum(Decimal(str(r.shifts_count or 0)) for r in attendance_records)
                gross_salary = total_shifts * (emp.current_shift_rate or Decimal("0.0"))
                
                # Sum of all ADVANCE transactions not yet settled
                advance_deducted = db.query(func.sum(StaffTransaction.amount)).filter(
                    StaffTransaction.profile_id == profile_id,
                    StaffTransaction.employee_id == emp.id,
                    StaffTransaction.transaction_type == "ADVANCE",
                    StaffTransaction.is_settled == False
                ).scalar() or Decimal("0.0")
                
                is_settled = False

            # 3. Construct the response object
            preview_list.append({
                "employee_id": str(emp.id),
                "profile_id": str(emp.profile_id),
                "name": emp.name,
                "total_shifts": float(total_shifts),
                "gross_salary": float(gross_salary),
                "unsettled_advance": float(advance_deducted),
                "suggested_net_pay": float(gross_salary - advance_deducted),
                "is_settled": is_settled  # Tells Flutter to disable the row
            })

        return preview_list