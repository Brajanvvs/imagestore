import re
from decimal import Decimal, ROUND_HALF_UP

from app.config import settings

EMAIL_RE = re.compile(r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$")
USERNAME_RE = re.compile(r"^[A-Za-z0-9._]{3,20}$")


def clean_spaces(value: str) -> str:
    return re.sub(r"\s+", " ", value or "").strip()


def money(value: Decimal) -> Decimal:
    return value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def as_decimal(value: float) -> Decimal:
    return Decimal(str(round(float(value), 2)))


def as_float(value: Decimal) -> float:
    return float(value)


def quote(subtotal: Decimal) -> dict[str, Decimal]:
    tax = money(subtotal * Decimal(str(settings.tax_rate)))
    if subtotal <= 0 or subtotal >= Decimal(str(settings.free_shipping_from)):
        shipping = Decimal("0.00")
    else:
        shipping = money(Decimal(str(settings.shipping_flat)))
    total = money(subtotal + tax + shipping)
    return {"subtotal": money(subtotal), "tax": tax, "shipping": shipping, "total": total}


def validate_person_name(value: str, label: str) -> str | None:
    name = clean_spaces(value)
    if not name:
        return f"El campo {label} es obligatorio"
    if len(name) > 60:
        return f"{label.capitalize()} admite máximo 60 caracteres"
    return None


def validate_username(value: str) -> str | None:
    username = (value or "").strip().lower()
    if not username:
        return "El usuario es obligatorio"
    if not USERNAME_RE.match(username):
        return "De 3 a 20 caracteres: letras, números, punto o guion bajo"
    return None


def validate_email(value: str) -> str | None:
    email = (value or "").strip().lower()
    if not email:
        return "El correo es obligatorio"
    if not EMAIL_RE.match(email):
        return "El correo no tiene un formato válido"
    return None


def validate_new_password(password: str, confirm: str, *, minimum: int = 8) -> dict[str, str]:
    errors: dict[str, str] = {}
    if not password:
        errors["password"] = "La contraseña es obligatoria"
    elif len(password) < minimum:
        errors["password"] = f"Mínimo {minimum} caracteres"
    elif len(password) > 128:
        errors["password"] = "Máximo 128 caracteres"
    if password != confirm:
        errors["password_confirm"] = "Las contraseñas no coinciden"
    return errors
