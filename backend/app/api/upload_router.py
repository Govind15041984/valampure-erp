from fastapi import APIRouter, Depends
from app.services.minio_service import (
    generate_purchase_presigned_url,
    make_canonical_purchase_name,
    finalize_purchase_bill,
    generate_profile_presigned_url,
)
from app.core.database import get_db
from app.core.security import create_access_token, get_current_user

router = APIRouter(tags=["Uploads"])

@router.get("/presign-purchase")
async def get_purchase_presign(
    file_ext: str = "jpg", 
    current_user = Depends(get_current_user)
):
    """
    Returns a temporary PUT URL for the Flutter app.
    The app will upload the file directly to MinIO using this.
    """
    return generate_purchase_presigned_url(
        profile_id=str(current_user.id), 
        file_ext=file_ext
    )