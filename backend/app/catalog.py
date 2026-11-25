import logging

from sqlalchemy.orm import Session

from app.config import settings
from app.image_provider import (
    CATEGORIES,
    CATEGORY_NAMES,
    PRICES,
    ImageProviderError,
    fetch_picsum,
    picsum_urls,
)
from app.models import Product

logger = logging.getLogger("imago.catalog")


def _crop(url: str, width: int) -> str:
    separator = "&" if "?" in url else "?"
    return f"{url}{separator}auto=format&fit=crop&w={width}&q=70"


SAMPLE_PRODUCTS = [
    ("Lago entre montañas", "Naturaleza", 18, "1501785888041-af3ef285b470", "Amanecer sobre un lago alpino, con picos todavía cubiertos de nieve."),
    ("Bosque en calma", "Naturaleza", 22, "1441974231531-c6227db76b6e", "Luz filtrada entre árboles altos. Una de las piezas más serenas del catálogo."),
    ("Colinas con niebla", "Naturaleza", 16, "1470071459604-3b5ec3a7fe05", "Capas de niebla sobre colinas verdes, ideal para fondos editoriales."),
    ("Avenida al atardecer", "Ciudad", 24, "1449824913935-59a10b8d2000", "Tráfico y luz cálida en una avenida. Fotografía urbana con mucho contraste."),
    ("Skyline nocturno", "Ciudad", 29, "1480714378408-67cf0d13bc1b", "Rascacielos encendidos. Sirve para portadas de ciudad y tecnología."),
    ("Calle empedrada", "Ciudad", 19, "1467269204594-9661b134dd2b", "Una calle europea estrecha, con fachadas de colores y cielo nublado."),
    ("Retrato en estudio", "Retrato", 34, "1531746020798-e6953c6e8e04", "Retrato con luz suave, pensado para campañas y perfiles editoriales."),
    ("Mirada lateral", "Retrato", 28, "1506794778202-cad84cf45f1d", "Retrato masculino con fondo neutro y mucha textura en la piel."),
    ("Luz de ventana", "Retrato", 31, "1524504388940-b1c1722653e1", "Retrato de moda junto a una ventana. Colores limpios y pose natural."),
    ("Mesa de temporada", "Comida", 15, "1504674900247-0877df9cc836", "Plato servido con hierbas y luz rasante. Cocina editorial."),
    ("Desayuno compartido", "Comida", 14, "1493770348161-369560ae357d", "Mesa de desayuno vista desde arriba, útil para recetas y menús."),
    ("Postre oscuro", "Comida", 17, "1478144592103-25e218a04891", "Postre con cacao y frutos rojos. Fondo oscuro para destacar el producto."),
    ("Trazo abstracto", "Arte", 26, "1547891654-e66ed7ebb907", "Pintura abstracta con capas de color. Pieza decorativa de gran formato."),
    ("Pigmento suelto", "Arte", 21, "1513364776144-60967b0f800f", "Detalle de pintura fresca. Textura y color para proyectos creativos."),
    ("Pinceles en mesa", "Arte", 18, "1460661419201-fd4cecdf8a8b", "Herramientas de estudio. Una foto de proceso, no solo de resultado."),
    ("Circuito de cerca", "Tecnología", 27, "1518770660439-4636190af475", "Placa electrónica con luces. Fondo técnico para producto y software."),
    ("Teléfono en mano", "Tecnología", 23, "1510557880182-3d4d3cba35a5", "Dispositivo móvil con pantalla encendida. Estilo publicitario limpio."),
    ("Escritorio de trabajo", "Tecnología", 25, "1517336714731-489689fd1ca8", "Portátil abierto sobre madera. Escena de trabajo remoto."),
    ("Mapa y salida", "Viajes", 20, "1488646953014-85cb44e25828", "Objetos de viaje sobre un mapa. Invita a planear la siguiente ruta."),
    ("Costa turquesa", "Viajes", 32, "1507525428034-b723cf961d3e", "Playa de agua clara y arena blanca. Una de las imágenes más luminosas."),
    ("Canal al mediodía", "Viajes", 30, "1523906834658-6e24ef2386f9", "Ciudad sobre el agua, con góndolas y fachadas cálidas."),
]


def product_out(product: Product) -> dict:
    return {
        "id": product.id,
        "title": product.title,
        "description": product.description,
        "category": product.category,
        "price": round(product.price, 2),
        "image_url": product.image_url,
        "thumbnail_url": product.thumbnail_url,
        "source": product.source,
        "source_page": product.source_page or "",
        "attribution": product.attribution or "",
        "featured": product.featured,
    }


def catalog_meta(db: Session) -> dict:
    picsum_count = db.query(Product).filter(Product.source == "picsum").count()
    sample_count = db.query(Product).filter(Product.source == "sample").count()
    if picsum_count:
        source = "picsum"
    elif sample_count:
        source = "sample"
    else:
        source = "empty"
    present = {row[0] for row in db.query(Product.category).distinct()}
    categories = [name for name in CATEGORY_NAMES if name in present]
    return {
        "source": source,
        "google_configured": True,
        "provider": "picsum",
        "provider_ready": True,
        "tax_rate": settings.tax_rate,
        "shipping_flat": settings.shipping_flat,
        "free_shipping_from": settings.free_shipping_from,
        "categories": categories,
    }


def seed_sample(db: Session) -> None:
    rows = []
    for index, (title, category, price, photo_id, text) in enumerate(SAMPLE_PRODUCTS):
        base = f"https://images.unsplash.com/photo-{photo_id}"
        rows.append(
            Product(
                title=title,
                description=(
                    f"{text} Imagen de muestra para la demostración de Imago. "
                    "La compra es una simulación y no entrega un archivo con licencia comercial."
                ),
                category=category,
                price=price,
                image_url=_crop(base, 1400),
                thumbnail_url=_crop(base, 800),
                source="sample",
                source_page=f"https://unsplash.com/photos/{photo_id}",
                attribution="Unsplash",
                featured=index % 3 == 0,
                sort_order=index,
            )
        )
    db.add_all(rows)
    db.commit()


def sync_catalog(db: Session) -> int:
    """Sincroniza el catálogo con Lorem Picsum (gratis, sin tarjeta)."""
    photos = fetch_picsum(page=1, limit=30) + fetch_picsum(page=2, limit=30)
    rows: list[Product] = []
    order = 0
    photo_index = 0
    for category in CATEGORIES:
        for index, title in enumerate(category["titles"]):
            if photo_index >= len(photos):
                break
            photo = photos[photo_index]
            photo_index += 1
            photo_id = photo["id"]
            author = str(photo.get("author") or "Lorem Picsum")
            image_url, thumbnail_url = picsum_urls(photo_id)
            rows.append(
                Product(
                    title=title,
                    description=(
                        f"Fotografía de {category['name'].lower()} obtenida con la API pública de Lorem Picsum. "
                        f"Autor: {author}. La compra en Imago es una simulación académica."
                    ),
                    category=category["name"],
                    price=PRICES[index % len(PRICES)],
                    image_url=image_url,
                    thumbnail_url=thumbnail_url,
                    source="picsum",
                    source_page=f"https://picsum.photos/id/{photo_id}/info",
                    attribution=author[:160],
                    featured=index == 0,
                    sort_order=order,
                )
            )
            order += 1
    if len(rows) < 4:
        raise ImageProviderError("Lorem Picsum no devolvió suficientes imágenes para armar el catálogo.")
    try:
        db.query(Product).delete(synchronize_session=False)
        db.add_all(rows)
        db.commit()
    except Exception:
        db.rollback()
        raise
    return len(rows)


def ensure_catalog(db: Session) -> None:
    if db.query(Product).filter(Product.source == "picsum").count() == 0:
        try:
            count = sync_catalog(db)
            logger.info("Catálogo sincronizado con Lorem Picsum: %s imágenes", count)
            return
        except ImageProviderError as exc:
            logger.warning("No se sincronizó Picsum: %s", exc)
    if db.query(Product).count() == 0:
        seed_sample(db)
        logger.info("Catálogo de muestra cargado")
