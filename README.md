# Imago

Tienda de imágenes hecha con Flutter y una API REST en FastAPI. El usuario se registra, inicia sesión con JWT, recorre el catálogo, filtra, arma el carrito y simula una compra.

Las fotografías salen de **Lorem Picsum** (`https://picsum.photos`), una API pública y gratuita: sin clave y sin tarjeta. Si la red falla al arrancar, se usa un catálogo de muestra.

## Cuenta demo

- Usuario: `demo`
- Contraseña: `demo1234`
- Correo: `demo@imago.app`

## 1. Backend

Desde PowerShell, en la carpeta del proyecto:

```powershell
cd backend
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Documentación interactiva: http://127.0.0.1:8000/docs

No hace falta configurar claves de imágenes. Al iniciar, el backend pide fotos a Lorem Picsum. También puedes tocar **Cargar imágenes desde la API** en Home.

El correo de recuperación usa SMTP. Si `SMTP_HOST` está vacío, en desarrollo la app abre sola la pantalla de nueva contraseña con el código. Con SMTP configurado, el mensaje trae el código y un enlace a `http://127.0.0.1:8000/reset?token=...`.

## 2. App Flutter

En otra terminal, en la raíz del proyecto:

```powershell
flutter pub get
flutter run
```

- Emulador Android: la app llama a `http://10.0.2.2:8000`.
- Windows, iOS o Chrome: `http://127.0.0.1:8000`.
- Teléfono físico: `flutter run --dart-define=API_BASE_URL=http://IP_DE_TU_PC:8000`.

## Pantallas

Cualquiera puede ver el Home y el detalle de las imágenes. Al agregar al carrito, abrir Carrito o Perfil, se pide iniciar sesión o registrarse. También hay recuperación de contraseña, drawer, barra inferior, carrusel, buscador, categorías, grilla y Mis pedidos (con cuenta).

El IVA es 19%. El envío cuesta $3.50 y queda gratis desde $60. **Proceder al pago** no cobra: guarda el pedido como compra simulada.

## Endpoints

| Método | Ruta | Uso |
| --- | --- | --- |
| POST | `/auth/register` | Crear cuenta |
| POST | `/auth/login` | Devuelve el JWT |
| POST | `/auth/forgot-password` | Pide el enlace de restablecimiento |
| POST | `/auth/reset-password` | Guarda la nueva contraseña |
| GET | `/users/me` | Perfil. Header `Authorization: Bearer <token>` |
| PUT | `/users/me` | Actualiza nombre, apellidos y usuario |
| PUT | `/users/me/password` | Cambia la contraseña |
| GET | `/products` | Catálogo. Filtros opcionales `category` y `q` |
| GET | `/products/{id}` | Detalle |
| POST | `/products/sync` | Vuelve a pedir imágenes a Lorem Picsum |
| POST | `/orders` | Simula la compra |
| GET | `/orders` | Pedidos del usuario |

Cerrar sesión borra el JWT en el teléfono. El token no se guarda en el servidor.
