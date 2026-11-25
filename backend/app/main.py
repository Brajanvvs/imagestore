import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse

from app.catalog import ensure_catalog
from app.config import settings
from app.database import Base, SessionLocal, engine
from app.models import User
from app.routers.auth import router as auth_router
from app.routers.orders import router as orders_router
from app.routers.products import router as products_router
from app.routers.users import router as users_router
from app.security import hash_password

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")


def init_db() -> None:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        if db.query(User).filter(User.username == "demo").first() is None:
            db.add(
                User(
                    first_name="Ana",
                    last_name="Rivas",
                    username="demo",
                    email="demo@imago.app",
                    password_hash=hash_password("demo1234"),
                )
            )
            db.commit()
        ensure_catalog(db)
    finally:
        db.close()


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


app = FastAPI(
    title="Imago API",
    version="1.0.0",
    description="Tienda de imágenes. Catálogo vía Lorem Picsum (API gratuita) y compra simulada.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(users_router, prefix="/users", tags=["users"])
app.include_router(products_router, prefix="/products", tags=["products"])
app.include_router(orders_router, prefix="/orders", tags=["orders"])


@app.get("/health")
def health() -> dict:
    return {"ok": True, "provider": "picsum", "provider_ready": True}


RESET_PAGE = """<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Nueva contraseña · Imago</title>
  <style>
    :root { color-scheme: light; }
    body { margin: 0; font-family: Georgia, "Times New Roman", serif; background: #f3f0ea; color: #1c1915; }
    main { max-width: 420px; margin: 8vh auto; background: white; padding: 32px 28px; border-radius: 18px; box-shadow: 0 16px 40px rgba(28,25,21,.08); }
    p, label { font-family: "Segoe UI", sans-serif; }
    h1 { font-weight: 500; font-size: 32px; margin: 0 0 8px; }
    .muted { color: #746e66; line-height: 1.45; }
    label { display: block; margin: 18px 0 6px; font-size: 14px; }
    input { width: 100%; box-sizing: border-box; border: 1px solid #e4ddd2; background: #f8f5f0; border-radius: 12px; padding: 12px 14px; font-size: 16px; }
    button { margin-top: 22px; width: 100%; border: 0; border-radius: 12px; padding: 14px; background: #1c1915; color: white; font-size: 16px; cursor: pointer; }
    button:disabled { opacity: .6; cursor: wait; }
    .msg { margin-top: 16px; font-family: "Segoe UI", sans-serif; font-size: 14px; }
    .err { color: #b42318; }
    .ok { color: #2f6b4f; }
  </style>
</head>
<body>
  <main>
    <h1>Nueva contraseña</h1>
    <p class="muted">Elige una contraseña de al menos 8 caracteres. Este enlace llegó desde Imago.</p>
    <form id="form">
      <label for="password">Nueva contraseña</label>
      <input id="password" name="password" type="password" minlength="8" required />
      <label for="confirm">Verificar contraseña</label>
      <input id="confirm" name="confirm" type="password" minlength="8" required />
      <button id="send" type="submit">Guardar contraseña</button>
      <div id="msg" class="msg"></div>
    </form>
  </main>
  <script>
    const params = new URLSearchParams(location.search);
    const token = params.get("token") || "";
    const msg = document.getElementById("msg");
    const button = document.getElementById("send");
    if (token.length < 10) {
      msg.className = "msg err";
      msg.textContent = "El enlace no trae un código válido. Solicita uno nuevo desde la app.";
      button.disabled = true;
    }
    document.getElementById("form").addEventListener("submit", async (event) => {
      event.preventDefault();
      const password = document.getElementById("password").value;
      const confirm = document.getElementById("confirm").value;
      if (password.length < 8) {
        msg.className = "msg err";
        msg.textContent = "Mínimo 8 caracteres.";
        return;
      }
      if (password !== confirm) {
        msg.className = "msg err";
        msg.textContent = "Las contraseñas no coinciden.";
        return;
      }
      button.disabled = true;
      msg.textContent = "";
      try {
        const response = await fetch("/auth/reset-password", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ token, password, password_confirm: confirm })
        });
        const data = await response.json();
        const detail = data.detail;
        if (!response.ok) {
          const text = detail && detail.message ? detail.message : "No se pudo actualizar la contraseña.";
          const fields = detail && detail.fields ? Object.values(detail.fields).join(" ") : "";
          msg.className = "msg err";
          msg.textContent = fields || text;
          button.disabled = false;
          return;
        }
        msg.className = "msg ok";
        msg.textContent = data.message || "Contraseña actualizada. Vuelve a la app e inicia sesión.";
      } catch (error) {
        msg.className = "msg err";
        msg.textContent = "No hay conexión con la API.";
        button.disabled = false;
      }
    });
  </script>
</body>
</html>
"""


@app.get("/reset", response_class=HTMLResponse)
def reset_page() -> str:
    return RESET_PAGE


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
