from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from datetime import datetime, timedelta
from app.models.profiles_model import Profile  # Updated import
from app.core.database import SessionLocal
import os

# Better to pull these from your config/settings later
SECRET_KEY = os.getenv("SECRET_KEY", "valampure_secret_key_2026") 
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 30  # 30 Days (good for business apps)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        
        if user_id is None:
            raise credentials_exception
            
    except JWTError:
        raise credentials_exception

    db = SessionLocal()
    try:
        # 1. Fetch the user from the valampure_erp schema
        user = db.query(Profile).filter(Profile.id == user_id).first()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, 
                detail="User account not found"
            )

        # 2. Safety Check: Is the account active?
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="Account is deactivated"
            )

        # 3. Support Expiry Check: The "Monthly Lock"
        # If today is past the expiry date, block API access
        if user.support_expiry_date < datetime.utcnow().date():
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="Support period expired. Please contact developer for renewal."
            )

        # Return the actual SQLAlchemy object so you can use user.company_name etc. in routes
        return user
        
    finally:
        db.close()

# ... existing get_current_user code ...

# This is a new helper to restrict access
def check_admin_role(current_user: Profile = Depends(get_current_user)):
    if current_user.role != "OWNER":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Access denied. Owner privileges required."
        )
    return current_user