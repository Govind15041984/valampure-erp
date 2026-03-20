import os
import uuid
import json
import urllib.parse
from datetime import datetime, timedelta
from typing import Tuple, Optional
from minio import Minio
from minio.commonconfig import CopySource

# -----------------------
# Config / Constants (DYNAMIC FOR RENDER/LOCAL)
# -----------------------

# On Render, set MINIO_ENDPOINT to: your-minio-service.onrender.com
# Locally, it defaults to your internal IP or localhost
MINIO_HOST = os.getenv("MINIO_ENDPOINT", "192.168.18.150:9000")
ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "minioadmin")

# Automatic SSL Check: 
# Local IPs (192.168, 127.0.0.1) or 'localhost' use HTTP (False)
# Render production domains (.onrender.com) use HTTPS (True)
SECURE = not any(x in MINIO_HOST for x in ["localhost", "127.0.0.1", "192.168"])

# Protocol selection for URL construction
PROTOCOL = "https" if SECURE else "http"
MINIO_HTTP_PREFIX = f"{PROTOCOL}://{MINIO_HOST}"

# Valampure Specific Buckets
PROFILE_BUCKET = "valampure-profiles"
PURCHASE_BILL_BUCKET = "valampure-purchase-bills"
SALES_BILL_BUCKET = "valampure-sales-bills"

# MinIO client initialization
minio_client = Minio(
    MINIO_HOST, 
    access_key=ACCESS_KEY, 
    secret_key=SECRET_KEY, 
    secure=SECURE
)

# -----------------------
# Core Setup
# -----------------------

def _set_public_policy(bucket_name: str):
    """
    Automatically sets the bucket to Public Read-Only.
    This ensures Flutter can display images/PDFs without 403 errors.
    """
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"AWS": ["*"]},
                "Action": [
                    "s3:GetBucketLocation",
                    "s3:ListBucket",
                    "s3:GetObject"
                ],
                "Resource": [
                    f"arn:aws:s3:::{bucket_name}",
                    f"arn:aws:s3:::{bucket_name}/*"
                ]
            }
        ]
    }
    try:
        minio_client.set_bucket_policy(bucket_name, json.dumps(policy))
    except Exception as e:
        print(f"Failed to set policy for {bucket_name}: {e}")

def _ensure_bucket(bucket_name: str):
    try:
        if not minio_client.bucket_exists(bucket_name):
            minio_client.make_bucket(bucket_name)
            _set_public_policy(bucket_name)
    except Exception as e:
        print(f"⚠️ MinIO bucket check/create failed for {bucket_name}: {e}")

def init_minio():
    """Call this in main.py on startup"""
    try:
        _ensure_bucket(PROFILE_BUCKET)
        _ensure_bucket(PURCHASE_BILL_BUCKET)
        _ensure_bucket(SALES_BILL_BUCKET)
        print(f"✅ Valampure MinIO Ready at {MINIO_HTTP_PREFIX}")
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
    temp_name = f"tmp_{profile_id}_{uuid.uuid4().hex}.{file_ext}"
    try:
        upload_url = minio_client.presigned_put_object(
            PURCHASE_BILL_BUCKET,
            temp_name,
            expires=timedelta(hours=1),
        )
        return {
            "upload_url": upload_url,
            "file_url": _object_http_url(PURCHASE_BILL_BUCKET, temp_name),
            "object_name": temp_name
        }
    except Exception as e:
        raise RuntimeError(f"Failed to generate presigned URL: {e}")

def make_canonical_purchase_name(partner_name: str, bill_no: str, bill_date: str) -> str:
    clean_partner = "".join(c for c in partner_name if c.isalnum())
    clean_bill = "".join(c for c in (bill_no or "NA") if c.isalnum() or c in ("-", "_"))
    
    try:
        dt = datetime.strptime(bill_date, "%Y-%m-%d")
    except:
        dt = datetime.utcnow()
    date_str = dt.strftime("%Y%m%d")

    return f"PUR_{clean_partner}_{clean_bill}_{date_str}_{uuid.uuid4().hex[:4]}.pdf"

def finalize_purchase_bill(src_temp_name: str, canonical_name: str) -> str:
    try:
        copy_src = CopySource(PURCHASE_BILL_BUCKET, src_temp_name)
        minio_client.copy_object(PURCHASE_BILL_BUCKET, canonical_name, copy_src)
        minio_client.remove_object(PURCHASE_BILL_BUCKET, src_temp_name)
        return _object_http_url(PURCHASE_BILL_BUCKET, canonical_name)
    except Exception as e:
        print(f"Cleanup error (non-fatal): {e}")
        return _object_http_url(PURCHASE_BILL_BUCKET, src_temp_name)

# -----------------------
# Profile Logic
# -----------------------

def generate_profile_presigned_url(profile_id: str, file_ext: str = "png"):
    temp_name = f"logo_tmp_{profile_id}_{uuid.uuid4().hex[:6]}.{file_ext}"
    try:
        upload_url = minio_client.presigned_put_object(
            PROFILE_BUCKET,
            temp_name,
            expires=timedelta(hours=1),
        )
        return {
            "upload_url": upload_url,
            "file_url": _object_http_url(PROFILE_BUCKET, temp_name),
            "object_name": temp_name
        }
    except Exception as e:
        raise RuntimeError(f"Failed to generate profile upload URL: {e}")

def finalize_profile_logo_update(profile_id: str, src_temp_name: str) -> str:
    file_ext = src_temp_name.split(".")[-1]
    canonical_name = f"profiles/{profile_id}/logo_{uuid.uuid4().hex[:4]}.{file_ext}"
    
    try:
        copy_src = CopySource(PROFILE_BUCKET, src_temp_name)
        minio_client.copy_object(PROFILE_BUCKET, canonical_name, copy_src)
        minio_client.remove_object(PROFILE_BUCKET, src_temp_name)
        return _object_http_url(PROFILE_BUCKET, canonical_name)
    except Exception as e:
        print(f"Logo finalization error: {e}")
        return _object_http_url(PROFILE_BUCKET, src_temp_name)

# -----------------------
# Sales Logic
# -----------------------

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
    date_str = inv_date.replace('-', '')
    return f"INV_{clean_partner}_{clean_inv}_{date_str}_{uuid.uuid4().hex[:4]}.pdf"

def finalize_sales_bill(src_temp_name: str, canonical_name: str) -> str:
    try:
        copy_src = CopySource(SALES_BILL_BUCKET, src_temp_name)
        minio_client.copy_object(SALES_BILL_BUCKET, canonical_name, copy_src)
        minio_client.remove_object(SALES_BILL_BUCKET, src_temp_name)
        return _object_http_url(SALES_BILL_BUCKET, canonical_name)
    except Exception as e:
        return _object_http_url(SALES_BILL_BUCKET, src_temp_name)