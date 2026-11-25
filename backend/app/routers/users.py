from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import api_error, get_current_user
from app.models import User
from app.schemas import MessageOut, PasswordIn, ProfileIn, UserOut
from app.security import hash_password, verify_password
from app.validators import clean_spaces, validate_new_password, validate_person_name, validate_username

router = APIRouter()


def user_payload(user: User) -> dict:
    return {
        "id": user.id,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "username": user.username,
        "email": user.email,
        "full_name": f"{user.first_name} {user.last_name}".strip(),
    }


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)) -> dict:
    return user_payload(user)


@router.put("/me", response_model=UserOut)
def update_me(
    body: ProfileIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    errors: dict[str, str] = {}
    first_error = validate_person_name(body.first_name, "nombre")
    last_error = validate_person_name(body.last_name, "apellidos")
    username_error = validate_username(body.username)
    if first_error:
        errors["first_name"] = first_error
    if last_error:
        errors["last_name"] = last_error
    if username_error:
        errors["username"] = username_error
    if errors:
        raise api_error(422, "Revisa los campos marcados", errors)

    username = body.username.strip().lower()
    taken = db.query(User).filter(User.username == username, User.id != user.id).first()
    if taken:
        raise api_error(409, "Ese nombre de usuario ya está en uso", {"username": "Ese usuario ya existe"})

    user.first_name = clean_spaces(body.first_name)
    user.last_name = clean_spaces(body.last_name)
    user.username = username
    db.commit()
    db.refresh(user)
    return user_payload(user)


@router.put("/me/password", response_model=MessageOut)
def change_password(
    body: PasswordIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    errors = validate_new_password(body.new_password, body.new_password_confirm)
    if "password" in errors:
        errors["new_password"] = errors.pop("password")
    if "password_confirm" in errors:
        errors["new_password_confirm"] = errors.pop("password_confirm")
    if not body.current_password:
        errors["current_password"] = "Ingresa tu contraseña actual"
    elif not verify_password(body.current_password, user.password_hash):
        errors["current_password"] = "La contraseña actual no coincide"
    elif body.current_password == body.new_password:
        errors["new_password"] = "Elige una contraseña distinta a la actual"
    if errors:
        raise api_error(422, "Revisa los campos marcados", errors)

    user.password_hash = hash_password(body.new_password)
    db.commit()
    return {"message": "Contraseña actualizada."}
