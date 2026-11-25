from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.catalog import catalog_meta, product_out, sync_catalog
from app.database import get_db
from app.deps import api_error, get_current_user
from app.image_provider import ImageProviderError
from app.models import Product, User
from app.schemas import ProductListOut, ProductOut, SyncOut

router = APIRouter()


@router.get("", response_model=ProductListOut)
def list_products(
    category: str | None = None,
    q: str | None = None,
    db: Session = Depends(get_db),
) -> dict:
    query = db.query(Product)
    if category and category.strip().lower() not in {"", "todos"}:
        query = query.filter(Product.category == category.strip())
    if q and q.strip():
        term = f"%{q.strip()}%"
        query = query.filter(Product.title.ilike(term))
    products = query.order_by(Product.sort_order, Product.id).all()
    return {"meta": catalog_meta(db), "products": [product_out(item) for item in products]}


@router.get("/{product_id}", response_model=ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)) -> dict:
    product = db.get(Product, product_id)
    if product is None:
        raise api_error(404, "No encontramos esa imagen")
    return product_out(product)


@router.post("/sync", response_model=SyncOut)
def sync_products(
    _: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    try:
        count = sync_catalog(db)
    except ImageProviderError as exc:
        current = db.query(Product).count()
        source = catalog_meta(db)["source"]
        return {
            "ok": False,
            "source": source,
            "count": current,
            "message": str(exc),
        }
    return {
        "ok": True,
        "source": "picsum",
        "count": count,
        "message": f"Catálogo actualizado con {count} imágenes de Lorem Picsum (API gratuita).",
    }
