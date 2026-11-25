import json
import urllib.error
import urllib.request

CATEGORIES = [
    {"name": "Naturaleza", "titles": ["Lago al amanecer", "Bosque profundo", "Colinas con niebla", "Cascada lejana", "Campo abierto", "Cielo de tormenta"]},
    {"name": "Ciudad", "titles": ["Avenida nocturna", "Skyline urbano", "Calle empedrada", "Puente iluminado", "Barrio antiguo", "Torres de cristal"]},
    {"name": "Retrato", "titles": ["Luz de estudio", "Mirada lateral", "Retrato natural", "Perfil en sombra", "Sonrisa editorial", "Primer plano"]},
    {"name": "Comida", "titles": ["Mesa de temporada", "Desayuno compartido", "Postre oscuro", "Plato de autor", "Café y pan", "Fruta fresca"]},
    {"name": "Arte", "titles": ["Trazo abstracto", "Pigmento suelto", "Estudio creativo", "Textura en color", "Composición libre", "Obra en proceso"]},
    {"name": "Tecnología", "titles": ["Circuito de cerca", "Escritorio de trabajo", "Dispositivo móvil", "Luces de servidor", "Detalle de lente", "Mesa digital"]},
    {"name": "Viajes", "titles": ["Costa turquesa", "Mapa y salida", "Canal al mediodía", "Sendero remoto", "Estación de paso", "Horizonte lejano"]},
]

CATEGORY_NAMES = [item["name"] for item in CATEGORIES]
PRICES = [12.0, 15.0, 18.0, 22.0, 28.0, 34.0, 39.0, 45.0]


class ImageProviderError(Exception):
    pass


def fetch_picsum(page: int = 1, limit: int = 30) -> list[dict]:
    """Lorem Picsum: API pública y gratuita, sin clave ni tarjeta."""
    url = f"https://picsum.photos/v2/list?page={page}&limit={limit}"
    request = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": "Imago/1.0"})
    try:
        with urllib.request.urlopen(request, timeout=25) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise ImageProviderError(f"Lorem Picsum HTTP {exc.code}: {body[:200]}") from exc
    except urllib.error.URLError as exc:
        raise ImageProviderError(f"No se pudo contactar a Lorem Picsum: {exc.reason}") from exc
    if not isinstance(payload, list) or not payload:
        raise ImageProviderError("Lorem Picsum no devolvió imágenes")
    return [item for item in payload if isinstance(item, dict) and item.get("id") is not None]


def picsum_urls(photo_id: str | int) -> tuple[str, str]:
    photo_id = str(photo_id)
    return (
        f"https://picsum.photos/id/{photo_id}/1400/1000",
        f"https://picsum.photos/id/{photo_id}/800/600",
    )
