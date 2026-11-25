from decimal import Decimal

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import api_error, get_current_user
from app.models import Order, OrderItem, Product, User
from app.schemas import OrderIn, OrderOut
from app.validators import as_decimal, as_float, quote

router = APIRouter()


def order_payload(order: Order) -> dict:
    return {
        "id": order.id,
        "subtotal": round(order.subtotal, 2),
        "tax": round(order.tax, 2),
        "shipping": round(order.shipping, 2),
        "total": round(order.total, 2),
        "status": order.status,
        "created_at": order.created_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "items": [
            {
                "product_id": item.product_id,
                "title": item.title,
                "unit_price": round(item.unit_price, 2),
                "quantity": item.quantity,
                "image_url": item.image_url,
                "line_total": round(item.unit_price * item.quantity, 2),
            }
            for item in order.items
        ],
    }


@router.get("", response_model=list[OrderOut])
def list_orders(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[dict]:
    orders = (
        db.query(Order)
        .filter(Order.user_id == user.id)
        .order_by(Order.created_at.desc(), Order.id.desc())
        .all()
    )
    return [order_payload(order) for order in orders]


@router.post("", response_model=OrderOut, status_code=201)
def create_order(
    body: OrderIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    if not body.items:
        raise api_error(422, "El carrito está vacío")

    subtotal = Decimal("0.00")
    lines: list[tuple[Product, int]] = []
    for item in body.items:
        product = db.get(Product, item.product_id)
        if product is None:
            raise api_error(
                400,
                "Una imagen del carrito ya no está en el catálogo. Vuelve a Home y arma el pedido de nuevo.",
            )
        subtotal += as_decimal(product.price) * item.quantity
        lines.append((product, item.quantity))

    totals = quote(subtotal)
    order = Order(
        user_id=user.id,
        subtotal=as_float(totals["subtotal"]),
        tax=as_float(totals["tax"]),
        shipping=as_float(totals["shipping"]),
        total=as_float(totals["total"]),
        status="paid",
    )
    for product, quantity in lines:
        order.items.append(
            OrderItem(
                product_id=product.id,
                title=product.title,
                unit_price=round(product.price, 2),
                quantity=quantity,
                image_url=product.thumbnail_url or product.image_url,
            )
        )
    db.add(order)
    db.commit()
    db.refresh(order)
    return order_payload(order)


@router.get("/{order_id}", response_model=OrderOut)
def get_order(
    order_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == user.id).first()
    if order is None:
        raise api_error(404, "No encontramos ese pedido")
    return order_payload(order)
