import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine

load_dotenv(Path(__file__).resolve().parent / ".env")

DEFAULT_DATABASE_URL = (
    "postgresql+psycopg2://postgres:postgres@localhost:5432/taxi"
)


def get_database_url() -> str:
    return os.getenv("DATABASE_URL", DEFAULT_DATABASE_URL)


def get_engine() -> Engine:
    return create_engine(get_database_url())
