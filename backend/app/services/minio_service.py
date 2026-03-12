import uuid
import urllib.parse
from datetime import datetime, timedelta
from typing import Tuple, Optional
from minio import Minio
from minio.commonconfig import CopySource

# -----------------------
# Config / Constants
# -----------------------
MINIO_HOST = "192.168.18.150:9000"
MINIO_HTTP_PREFIX = f"http://{MINIO_HOST}"
ACCESS_KEY = "minioadmin"
SECRET_KEY = "minioadmin"
SECURE = False

# Valampure Specific Buckets
PROFILE_BUCKET = "valampure-profiles"
PURCHASE_BILL_BUCKET = "valampure-purchase-bills"
SALES_BILL_BUCKET = "valampure-sales-bills"

# MinIO client
minio_client = Minio(
    MINIO_HOST, 
    access_key=ACCESS_KEY, 
    secret_key=SECRET_KEY, 
    secure=SECURE
)

# -----------------------
# Core Setup
# -----------------------
def _ensure_bucket(bucket_name: str):
    try:
        if not minio_client.bucket_exists(bucket_name):
            minio_client.make_bucket(bucket_name)
    except Exception as e:
        raise RuntimeError(f"MinIO bucket check/create failed for {bucket_name}: {e}")

def init_minio():
    """Call this in main.py on startup"""
    try:
        _ensure_bucket(PROFILE_BUCKET)
        _ensure_bucket(PURCHASE_BILL_BUCKET)
        _ensure_bucket(SALES_BILL_BUCKET)
        print("✅ Valampure MinIO Buckets Ready")
    except Exception as e:
        print("⚠️ MinIO initialization failed:", e)

# -----------------------
# Internal Helpers
# -----------------------
def _object_http_url(bucket: str, object_name: str) -> str:
    """Constructs the public-facing URL for an object."""
    parts = object_name.split("/")
    quoted = "/".join(urllib.parse.quote(p, safe="") for p in parts)
    return f"{MINIO_HTTP_PREFIX}/{bucket}/{quoted}"

# -----------------------
# Purchase Bill Logic
# -----------------------

def generate_purchase_presigned_url(profile_id: str, file_ext: str = "jpg"):
    """
    Step 1: Generate a temporary URL for Flutter to upload the raw file.
    Flutter uses the 'upload_url' for PUT.
    """
    # Create a temporary unique name
    temp_name = f"tmp_{profile_id}_{uuid.uuid4().hex}.{file_ext}"

    try:
        upload_url = minio_client.presigned_put_object(
            PURCHASE_BILL_BUCKET,
            temp_name,
            expires=timedelta(hours=1),
        )
    except Exception as e:
        raise RuntimeError(f"Failed to generate presigned URL: {e}")

    final_http_url = _object_http_url(PURCHASE_BILL_BUCKET, temp_name)
    
    return {
        "upload_url": upload_url,
        "file_url": final_http_url,
        "object_name": temp_name
    }

def make_canonical_purchase_name(partner_name: str, bill_no: str, bill_date: str) -> str:
    """
    Builds a clean filename: PUR_JaiTraders_Inv101_20260304.jpg
    """
    # Sanitize inputs
    clean_partner = "".join(c for c in partner_name if c.isalnum())
    clean_bill = "".join(c for c in (bill_no or "NA") if c.isalnum() or c in ("-", "_"))
    
    # Format date
    try:
        dt = datetime.strptime(bill_date, "%Y-%m-%d")
    except:
        dt = datetime.utcnow()
    date_str = dt.strftime("%Y%m%d")

    return f"PUR_{clean_partner}_{clean_bill}_{date_str}_{uuid.uuid4().hex[:4]}.pdf"

def finalize_purchase_bill(src_temp_name: str, canonical_name: str) -> str:
    """
    Step 2: After DB save is successful, move the file from temp to canonical name.
    """
    try:
        copy_src = CopySource(PURCHASE_BILL_BUCKET, src_temp_name)
        minio_client.copy_object(PURCHASE_BILL_BUCKET, canonical_name, copy_src)
        
        # Delete the temp file
        minio_client.remove_object(PURCHASE_BILL_BUCKET, src_temp_name)
        
        return _object_http_url(PURCHASE_BILL_BUCKET, canonical_name)
    except Exception as e:
        # If copy fails, we still return the temp URL so the data isn't lost
        print(f"Cleanup error (non-fatal): {e}")
        return _object_http_url(PURCHASE_BILL_BUCKET, src_temp_name)

# -----------------------
# Profile Logic
# -----------------------
def generate_profile_presigned_url(profile_id: str, file_ext: str = "jpg"):
    object_name = f"profiles/{profile_id}/{uuid.uuid4()}.{file_ext}"
    try:
        upload_url = minio_client.presigned_put_object(
            PROFILE_BUCKET,
            object_name,
            expires=timedelta(hours=1),
        )
        return {
            "upload_url": upload_url,
            "file_url": _object_http_url(PROFILE_BUCKET, object_name),
            "object_name": object_name,
        }
    except Exception as e:
        raise RuntimeError(f"Profile upload error: {e}")

def generate_sales_presigned_url(profile_id: str, file_ext: str = "pdf"):
    temp_name = f"tmp_sale_{profile_id}_{uuid.uuid4().hex}.{file_ext}"
    try:
        upload_url = minio_client.presigned_put_object(
            SALES_BILL_BUCKET,
            temp_name,
            expires=timedelta(hours=1),
        )
        return {
            "upload_url": upload_url,
            "object_name": temp_name
        }
    except Exception as e:
        raise RuntimeError(f"Failed to generate sales presigned URL: {e}")

def make_canonical_sales_name(partner_name: str, inv_no: str, inv_date: str) -> str:
    clean_partner = "".join(c for c in partner_name if c.isalnum())
    clean_inv = "".join(c for c in inv_no if c.isalnum() or c in ("-", "_"))
    
    # Format: INV_Customer_Inv123_20260306_abcd.pdf
    return f"INV_{clean_partner}_{clean_inv}_{inv_date.replace('-', '')}_{uuid.uuid4().hex[:4]}.pdf"

def finalize_sales_bill(src_temp_name: str, canonical_name: str) -> str:
    try:
        copy_src = CopySource(SALES_BILL_BUCKET, src_temp_name)
        minio_client.copy_object(SALES_BILL_BUCKET, canonical_name, copy_src)
        minio_client.remove_object(SALES_BILL_BUCKET, src_temp_name)
        return _object_http_url(SALES_BILL_BUCKET, canonical_name)
    except Exception as e:
        return _object_http_url(SALES_BILL_BUCKET, src_temp_name)

