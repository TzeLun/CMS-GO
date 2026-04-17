from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    database_url: str = "postgresql://cms_user:cms_password@db:5432/cms_db"
    secret_key: str = "your-secret-key-change-this"
    openai_api_key: str = ""
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 10080  # 7 days

    class Config:
        env_file = ".env"


@lru_cache()
def get_settings():
    return Settings()
