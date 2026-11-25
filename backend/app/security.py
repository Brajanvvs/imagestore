import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone

import jwt

from app.config import settings


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 120_000)
    return f"{salt}${digest.hex()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        salt, digest = stored.split("$", 1)
    except ValueError:
        return False
    check = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 120_000)
    return hmac.compare_digest(check.hex(), digest)


def create_access_token(user_id: int) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_minutes)
    return jwt.encode({"sub": str(user_id), "exp": expire}, settings.secret_key, algorithm="HS256")


def decode_access_token(token: str) -> int:
    payload = jwt.decode(token, settings.secret_key, algorithms=["HS256"])
    return int(payload["sub"])
