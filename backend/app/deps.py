from typing import Annotated

import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.security import decode_access_token

bearer_scheme = HTTPBearer(auto_error=False)


def api_error(status: int, message: str, fields: dict[str, str] | None = None) -> HTTPException:
    return HTTPException(status_code=status, detail={"message": message, "fields": fields or {}})


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    if credentials is None or not credentials.credentials:
        raise api_error(401, "No autenticado")
    try:
        user_id = decode_access_token(credentials.credentials)
    except (jwt.PyJWTError, ValueError):
        raise api_error(401, "Sesión inválida o vencida") from None
    user = db.get(User, user_id)
    if user is None:
        raise api_error(401, "Sesión inválida o vencida")
    return user
