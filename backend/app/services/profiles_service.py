from sqlalchemy.orm import Session
from passlib.context import CryptContext
from app.models.profiles_model import Profile
from app.schemas.profiles_schema import UserCreate, ProfileUpdate
from uuid import UUID

# Setup for PIN encryption
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# USE: Converts a plain 4 or 6 digit PIN into a secure hash.
# WHEN: Triggered during Signup or when a user changes their PIN.
def hash_pin(pin: str) -> str:
    return pwd_context.hash(pin)

# USE: Compares the PIN entered at login with the hash stored in Render DB.
# WHEN: Triggered every time a user tries to Log In.
def verify_pin(plain_pin: str, hashed_pin: str) -> bool:
    return pwd_context.verify(plain_pin, hashed_pin)


# USE: Checks if a mobile number already exists in the valampure_erp schema.
# WHEN: Triggered during Signup to prevent duplicate accounts.
def get_profile_by_mobile(db: Session, mobile_number: str):
    return db.query(Profile).filter(Profile.mobile_number == mobile_number).first()


# USE: The main logic to create a brand new business profile.
# WHEN: Triggered when the "Register" button is clicked in the Flutter app.
def create_profile(db: Session, data: UserCreate):
    pin_hash = hash_pin(data.pin)
    profile = Profile(
        mobile_number=data.mobile,
        owner_name=data.owner_name,
        company_name=data.company_name,
        pin_hash=pin_hash,
        role=data.role if data.role else "OWNER"
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return profile


# USE: Validates credentials and returns the user record if successful.
# WHEN: Triggered at Login. It's the "Gatekeeper" of the app.
def authenticate_profile(db: Session, mobile_number: str, pin: str):
    profile = get_profile_by_mobile(db, mobile_number)
    if not profile:
        print(f"❌ Mobile {mobile_number} not found in Valampure Schema")
        return None
        
    is_valid = verify_pin(pin, profile.pin_hash)
    print(f"🔍 Checking PIN for {mobile_number}: Result: {is_valid}")
    
    if not is_valid:
        return None
    return profile


# USE: Updates specific fields like GST, Bank Details, or Area Code.
# WHEN: Triggered when the owner completes their "Business Profile" setup.
def update_profile_details(db: Session, profile_id: str, data: ProfileUpdate):
    db_query = db.query(Profile).filter(Profile.id == profile_id)
    db_profile = db_query.first()
    
    if not db_profile:
        return None
        
    # model_dump(exclude_unset=True) ensures we only update fields 
    # the user actually sent (like just the GSTIN or just the Bank)
    update_data = data.model_dump(exclude_unset=True)
    db_query.update(update_data, synchronize_session=False)
    
    db.commit()
    db.refresh(db_profile)
    return db_profile