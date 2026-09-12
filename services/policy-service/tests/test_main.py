from fastapi.testclient import TestClient

from app.main import app, policies

client = TestClient(app)


def setup_function() -> None:
    policies.clear()


def sample_policy() -> dict:
    return {
        "policy_number": "POL-2026-00001",
        "customer_name": "Prashant Saxena",
        "policy_type": "MOTOR",
        "coverage_amount": 500000,
        "premium_amount": 12000,
        "start_date": "2026-01-01",
        "expiry_date": "2027-01-01",
        "status": "ACTIVE",
    }


def test_health() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "healthy",
        "service": "insurance-policy-service",
    }


def test_create_policy() -> None:
    response = client.post("/policies", json=sample_policy())

    assert response.status_code == 201
    assert response.json()["policy_number"] == "POL-2026-00001"
    assert response.json()["status"] == "ACTIVE"


def test_get_policy() -> None:
    client.post("/policies", json=sample_policy())

    response = client.get("/policies/POL-2026-00001")

    assert response.status_code == 200
    assert response.json()["customer_name"] == "Prashant Saxena"


def test_duplicate_policy_returns_conflict() -> None:
    client.post("/policies", json=sample_policy())

    response = client.post("/policies", json=sample_policy())

    assert response.status_code == 409
    assert response.json()["detail"] == "Policy already exists"


def test_policy_not_found() -> None:
    response = client.get("/policies/POL-UNKNOWN")

    assert response.status_code == 404
    assert response.json()["detail"] == "Policy not found"


def test_invalid_policy_dates() -> None:
    request = sample_policy()
    request["expiry_date"] = "2025-12-31"

    response = client.post("/policies", json=request)

    assert response.status_code == 422
    assert response.json()["detail"] == (
        "Policy expiry date must be after the start date"
    )
