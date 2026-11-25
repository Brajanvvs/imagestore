from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_env: str = "development"
    secret_key: str = "imago-dev-secret-change-me"
    access_token_minutes: int = 60 * 24 * 7
    public_base_url: str = "http://127.0.0.1:8000"

    google_api_key: str = ""
    google_cse_id: str = ""

    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from: str = "Imago <no-reply@imago.app>"

    tax_rate: float = 0.19
    shipping_flat: float = 3.50
    free_shipping_from: float = 60.0

    @property
    def google_ready(self) -> bool:
        return bool(self.google_api_key.strip() and self.google_cse_id.strip())

    @property
    def is_development(self) -> bool:
        return self.app_env.strip().lower() == "development"


settings = Settings()
