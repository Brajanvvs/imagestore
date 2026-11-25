import logging
import smtplib
import urllib.parse
from email.message import EmailMessage

from app.config import settings

logger = logging.getLogger("imago.mail")


def send_reset_email(to_email: str, name: str, token: str) -> bool:
    link = f"{settings.public_base_url.rstrip('/')}/reset?token={urllib.parse.quote(token)}"
    text = (
        f"Hola {name},\n\n"
        "Recibimos una solicitud para restablecer tu contraseña en Imago.\n\n"
        "Abre la aplicación, entra en ¿Olvidaste tu contraseña? y pega este código:\n\n"
        f"{token}\n\n"
        "También puedes abrir este enlace en el equipo donde corre la API "
        "para elegir la nueva contraseña:\n\n"
        f"{link}\n\n"
        "El código vence en 30 minutos. Si no fuiste tú, ignora este mensaje.\n"
    )
    if not settings.smtp_host.strip():
        if settings.is_development:
            logger.info("SMTP no configurado. Restablecimiento para %s. Token: %s Enlace: %s", to_email, token, link)
        return False

    message = EmailMessage()
    message["Subject"] = "Restablece tu contraseña de Imago"
    message["From"] = settings.smtp_from or settings.smtp_user
    message["To"] = to_email
    message.set_content(text)
    try:
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=20) as smtp:
            smtp.starttls()
            if settings.smtp_user.strip():
                smtp.login(settings.smtp_user, settings.smtp_password)
            smtp.send_message(message)
    except (OSError, smtplib.SMTPException) as exc:
        logger.exception("No se pudo enviar el correo de restablecimiento: %s", exc)
        return False
    return True
