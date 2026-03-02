from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.services.profiles_service import (
    get_profile_by_mobile, 
    authenticate_profile,  
)
from app.core.security import create_access_token

router = APIRouter(tags=["Auth"])

# USE: Public endpoint to create a new account.
# WHEN: The very first time a business owner uses the app.
@router.post("/signup", response_model=ProfileOut)
def signup(data: UserCreate, db: Session = Depends(get_db)):
    existing_user = get_profile_by_mobile(db, data.mobile)
    if existing_user:
        raise HTTPException(status_code=400, detail="Mobile already registered")
    return create_profile(db, data)

# USE: Public endpoint to exchange Mobile/PIN for a "Golden Ticket" (JWT Token).
# WHEN: Every time the user opens the app and their previous session has expired.
@router.post("/login")
def login(mobile: str, pin: str, db: Session = Depends(get_db)):
    user = authenticate_profile(db, mobile, pin)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid Credentials")
    
    # After verifying the PIN, we create the encrypted token
    access_token = create_access_token(data={"sub": str(user.id), "role": user.role})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {"company": user.company_name, "role": user.role}
    }