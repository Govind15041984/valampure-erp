import uuid
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func, case, text
from typing import List, Dict, Any
from datetime import datetime, timedelta
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.partner_model import Partner
from app.models.payments_model import Payment
from app.models.sales_model import SalesMaster, SalesDetail
from app.models.purchase_model import PurchaseMaster
from app.models.inventory_model import FinishedGoodsStock
from app.models.manufacturing_entry_model import ManufacturingEntry
from app.models.expenses_model import DailyExpense # Ensure this is imported
from sqlalchemy import extract

router = APIRouter(tags=["Dashboard"])

@router.get("/summary")
def get_dashboard_summary(
    db: Session = Depends(get_db),
    current_user: Any = Depends(get_current_user)
):
    now = datetime.now()
    today = now.date()
    yesterday = today - timedelta(days=1)
    thirty_days_ago = today - timedelta(days=30)
    seven_days_ago = today - timedelta(days=7)
    
    pid = current_user.id

    # --- 1. FINANCIAL HEALTH & AGEING ---
    receivable = db.query(func.sum(Partner.current_balance))\
        .filter(Partner.profile_id == pid, Partner.partner_type == "BUYER").scalar() or 0
    
    payable = db.query(func.sum(Partner.current_balance))\
        .filter(Partner.profile_id == pid, Partner.partner_type == "SUPPLIER").scalar() or 0

 
    monthly_expenses = db.query(func.sum(DailyExpense.amount)).filter(
        DailyExpense.profile_id == pid,
        extract('year', DailyExpense.expense_date) == now.year,
        extract('month', DailyExpense.expense_date) == now.month
    ).scalar() or 0

    # Categorized Expenses for the current month
    category_summary = db.query(
        DailyExpense.category,
        func.sum(DailyExpense.amount).label("total")
    ).filter(
        DailyExpense.profile_id == pid,
        extract('year', DailyExpense.expense_date) == now.year,
        extract('month', DailyExpense.expense_date) == now.month
    ).group_by(DailyExpense.category).all()

    # Convert to a list of dictionaries for JSON
    expense_breakdown = [
        {"category": c.category or "Other", "amount": float(c.total)} 
        for c in category_summary
    ]
    
    overdue_receivable = db.query(func.sum(SalesMaster.grand_total))\
        .filter(SalesMaster.profile_id == pid, SalesMaster.invoice_date <= thirty_days_ago)\
        .scalar() or 0

    # --- 2. SALES & REVENUE INTELLIGENCE ---
    count_today = db.query(func.count(SalesMaster.id))\
        .filter(SalesMaster.profile_id == pid, SalesMaster.invoice_date == today).scalar() or 0
    
    count_yesterday = db.query(func.count(SalesMaster.id))\
        .filter(SalesMaster.profile_id == pid, SalesMaster.invoice_date == yesterday).scalar() or 0
    
    top_customers = db.query(
        Partner.name, 
        func.sum(SalesMaster.grand_total).label("total_spend")
    ).join(SalesMaster, SalesMaster.partner_id == Partner.id)\
     .filter(SalesMaster.profile_id == pid, SalesMaster.invoice_date >= thirty_days_ago)\
     .group_by(Partner.name)\
     .order_by(text("total_spend DESC")).limit(5).all()

    # --- 3. OPERATIONAL PULSE ---
    prod_trend = db.query(
        func.date(ManufacturingEntry.production_date).label("date"), 
        func.sum(ManufacturingEntry.total_mts).label("prod_mts")
    ).filter(ManufacturingEntry.profile_id == pid, ManufacturingEntry.production_date >= seven_days_ago)\
     .group_by(text("date")).all()

    sales_trend = db.query(
        func.date(SalesMaster.invoice_date).label("date"),
        func.sum(SalesDetail.total_qty).label("sales_mts")
    ).join(SalesDetail, SalesDetail.sales_id == SalesMaster.id)\
     .filter(SalesMaster.profile_id == pid, SalesMaster.invoice_date >= seven_days_ago)\
     .group_by(text("date")).all()

    pulse_map = {str(today - timedelta(days=i)): {"prod": 0.0, "sales": 0.0} for i in range(8)}
    for p in prod_trend:
        pulse_map[str(p.date)]["prod"] = float(p.prod_mts or 0)
    for s in sales_trend:
        pulse_map[str(s.date)]["sales"] = float(s.sales_mts or 0)

    sorted_pulse = sorted(pulse_map.items())
    gap_data = [{"date": d, "prod": v["prod"], "sales": v["sales"]} for d, v in sorted_pulse]

    # --- 4. RECENT PURCHASES ---
    recent_purchases = db.query(PurchaseMaster)\
        .filter(PurchaseMaster.profile_id == pid)\
        .order_by(PurchaseMaster.bill_date.desc()).limit(5).all()

    # --- 5. STOCK & ALERTS ---
    all_stock = db.query(FinishedGoodsStock).filter(FinishedGoodsStock.profile_id == pid).all()
    critical_stock = [
        {"size": s.size_mm, "desc": s.description, "boxes": s.total_boxes_in_hand or 0} 
        for s in all_stock if (s.total_boxes_in_hand or 0) < 10
    ]

    return {
        "finance": {
            "receivable": round(float(receivable or 0), 2),
            "payable": round(float(payable or 0), 2),
            "monthly_expenses": round(float(monthly_expenses or 0), 2),
            "expense_breakdown": expense_breakdown,
            "net_balance": round(float(receivable or 0) - (float(payable or 0) + float(monthly_expenses or 0)), 2),
            "overdue_30_days": round(float(overdue_receivable or 0), 2),
        },
        "growth": {
            "today_count": int(count_today),
            "yesterday_count": int(count_yesterday),
            "top_customers": [{"name": c.name, "amount": float(c.total_spend or 0)} for c in top_customers]
        },
        "pulse": {
            "gap_data": gap_data,
            "critical_stock": critical_stock
        },
        "production_chart": [{"date": d, "mts": v["prod"]} for d, v in sorted_pulse],
        "stock": [
            {"description": s.description, "size": s.size_mm, "boxes": s.total_boxes_in_hand or 0, "mts": float(s.total_mts_in_hand or 0)} 
            for s in all_stock
        ],
        "recent_purchases": [
            {"bill": p.bill_number, "date": str(p.bill_date), "amount": float(p.final_amount or 0)} 
            for p in recent_purchases
        ]
    }