import secrets
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.deps import api_error
from app.mailer import send_reset_email
from app.models import PasswordReset, User
from app.schemas import ForgotIn, ForgotOut, LoginIn, LoginOut, MessageOut, RegisterIn, ResetIn
from app.security import create_access_token, hash_password, verify_password
from app.validators import clean_spaces, validate_email, validate_new_password, validate_person_name, validate_username
from app.routers.users import user_payload

router = APIRouter()


@router.post("/register", response_model=MessageOut, status_code=201)
def register(body: RegisterIn, db: Session = Depends(get_db)) -> dict:
    errors: dict[str, str] = {}
    first_error = validate_person_name(body.first_name, "nombre")
    last_error = validate_person_name(body.last_name, "apellidos")
    username_error = validate_username(body.username)
    email_error = validate_email(body.email)
    if first_error:
        errors["first_name"] = first_error
    if last_error:
        errors["last_name"] = last_error
    if username_error:
        errors["username"] = username_error
    if email_error:
        errors["email"] = email_error
    errors.update(validate_new_password(body.password, body.password_confirm))
    if errors:
        raise api_error(422, "Revisa los campos marcados", errors)

    username = body.username.strip().lower()
    email = body.email.strip().lower()
    if db.query(User).filter(User.username == username).first():
        raise api_error(409, "Ese nombre de usuario ya está en uso", {"username": "Ese usuario ya existe"})
    if db.query(User).filter(User.email == email).first():
        raise api_error(409, "Ese correo ya está registrado", {"email": "Ese correo ya está registrado"})

    db.add(
        User(
            first_name=clean_spaces(body.first_name),
            last_name=clean_spaces(body.last_name),
            username=username,
            email=email,
            password_hash=hash_password(body.password),
        )
    )
    db.commit()
    return {"message": "Cuenta creada. Ya puedes iniciar sesión."}


@router.post("/login", response_model=LoginOut)
def login(body: LoginIn, db: Session = Depends(get_db)) -> dict:
    identifier = body.identifier.strip().lower()
    errors: dict[str, str] = {}
    if not identifier:
        errors["identifier"] = "Ingresa tu usuario o correo"
    elif "@" in identifier and validate_email(identifier):
        errors["identifier"] = "El correo no tiene un formato válido"
    if not body.password:
        errors["password"] = "Ingresa tu contraseña"
    elif len(body.password) < 6:
        errors["password"] = "Mínimo 6 caracteres"
    if errors:
        raise api_error(422, "Revisa los campos marcados", errors)

    user = db.query(User).filter((User.username == identifier) | (User.email == identifier)).first()
    if user is None or not verify_password(body.password, user.password_hash):
        raise api_error(401, "Usuario o contraseña incorrectos")
    return {
        "access_token": create_access_token(user.id),
        "token_type": "bearer",
        "user": user_payload(user),
    }


@router.post("/forgot-password", response_model=ForgotOut)
def forgot_password(body: ForgotIn, db: Session = Depends(get_db)) -> dict:
    email_error = validate_email(body.email)
    if email_error:
        raise api_error(422, email_error, {"email": email_error})
    email = body.email.strip().lower()
    message = "Si el correo está registrado, enviaremos un enlace para restablecer la contraseña."
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        return {"message": message, "reset_token": None}

    token = secrets.token_urlsafe(32)
    db.add(
        PasswordReset(
            user_id=user.id,
            token=token,
            expires_at=datetime.utcnow() + timedelta(minutes=30),
            used=False,
        )
    )
    db.commit()
    sent = send_reset_email(user.email, user.first_name, token)
    payload: dict = {"message": message, "reset_token": None}
    if settings.is_development and not sent:
        payload["reset_token"] = token
        payload["message"] = (
            "Modo desarrollo: no hay servidor de correo. "
            "Usa el código para elegir una nueva contraseña. En producción este código llega por email."
        )
    return payload


@router.post("/reset-password", response_model=MessageOut)
def reset_password(body: ResetIn, db: Session = Depends(get_db)) -> dict:
    errors = validate_new_password(body.password, body.password_confirm)
    token = body.token.strip()
    if len(token) < 10:
        errors["token"] = "Ingresa el código que llegó a tu correo"
    if errors:
        raise api_error(422, "Revisa los campos marcados", errors)

    row = db.query(PasswordReset).filter(PasswordReset.token == token, PasswordReset.used.is_(False)).first()
    if row is None or row.expires_at < datetime.utcnow():
        raise api_error(400, "El código no es válido o venció", {"token": "Código inválido o vencido"})
    user = db.get(User, row.user_id)
    if user is None:
        raise api_error(400, "El código no es válido o venció", {"token": "Código inválido o vencido"})

    user.password_hash = hash_password(body.password)
    db.query(PasswordReset).filter(PasswordReset.user_id == user.id, PasswordReset.used.is_(False)).update(
        {"used": True},
        synchronize_session=False,
    )
    db.commit()
    return {"message": "Contraseña actualizada. Ya puedes iniciar sesión."}
