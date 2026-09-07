import pytest
from fastapi.testclient import TestClient

from app.main import app, claims


@pytest.fixture(autouse=True)
def clear_claim_store():
    claims.clear()
    yield
    claims.clear()


@pytest.fixture
def client():
    return TestClient(app)
