from pydantic import BaseModel, ConfigDict, Field


class UserOut(BaseModel):
    id: int
    first_name: str
    last_name: str
    username: str
    email: str
    full_name: str


class LoginIn(BaseModel):
    identifier: str = ""
    password: str = ""


class LoginOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class RegisterIn(BaseModel):
    first_name: str = ""
    last_name: str = ""
    username: str = ""
    email: str = ""
    password: str = ""
    password_confirm: str = ""


class ForgotIn(BaseModel):
    email: str = ""


class ForgotOut(BaseModel):
    message: str
    reset_token: str | None = None


class ResetIn(BaseModel):
    token: str = ""
    password: str = ""
    password_confirm: str = ""


class MessageOut(BaseModel):
    message: str


class ProfileIn(BaseModel):
    first_name: str = ""
    last_name: str = ""
    username: str = ""


class PasswordIn(BaseModel):
    current_password: str = ""
    new_password: str = ""
    new_password_confirm: str = ""


class ProductOut(BaseModel):
    id: int
    title: str
    description: str
    category: str
    price: float
    image_url: str
    thumbnail_url: str
    source: str
    source_page: str = ""
    attribution: str = ""
    featured: bool = False


class MetaOut(BaseModel):
    source: str
    google_configured: bool = True
    provider: str = "picsum"
    provider_ready: bool = True
    tax_rate: float
    shipping_flat: float
    free_shipping_from: float
    categories: list[str]


class ProductListOut(BaseModel):
    meta: MetaOut
    products: list[ProductOut]


class SyncOut(BaseModel):
    ok: bool
    source: str
    count: int
    message: str


class OrderItemIn(BaseModel):
    product_id: int
    quantity: int = Field(default=1, ge=1, le=20)


class OrderIn(BaseModel):
    items: list[OrderItemIn] = []


class OrderItemOut(BaseModel):
    product_id: int
    title: str
    unit_price: float
    quantity: int
    image_url: str
    line_total: float


class OrderOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    subtotal: float
    tax: float
    shipping: float
    total: float
    status: str
    created_at: str
    items: list[OrderItemOut]
