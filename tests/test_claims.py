import app.main as claim_main
from app.policy_client import (
    PolicyInactiveError,
    PolicyNotFoundError,
    PolicyServiceUnavailableError,
)


def valid_claim_payload() -> dict:
    return {
        "policy_number": "POL-10001",
        "claimant_name": "Anita Sharma",
        "claim_type": "Vehicle Damage",
        "estimated_amount": 75000.0,
    }


def active_policy() -> dict:
    return {
        "policy_number": "POL-10001",
        "customer_name": "Anita Sharma",
        "policy_type": "MOTOR",
        "status": "ACTIVE",
    }


def test_create_claim_for_active_policy(client, monkeypatch) -> None:
    monkeypatch.setattr(
        claim_main,
        "validate_policy",
        lambda policy_number: active_policy(),
    )

    response = client.post("/claims", json=valid_claim_payload())
    body = response.json()

    assert response.status_code == 201
    assert body["policy_number"] == "POL-10001"
    assert body["status"] == "SUBMITTED"
    assert body["claim_id"]


def test_get_existing_claim(client, monkeypatch) -> None:
    monkeypatch.setattr(
        claim_main,
        "validate_policy",
        lambda policy_number: active_policy(),
    )

    created = client.post(
        "/claims",
        json=valid_claim_payload(),
    ).json()

    response = client.get(f"/claims/{created['claim_id']}")

    assert response.status_code == 200
    assert response.json()["claim_id"] == created["claim_id"]


def test_policy_not_found_blocks_claim(client, monkeypatch) -> None:
    def raise_policy_not_found(policy_number: str) -> None:
        raise PolicyNotFoundError(
            f"Policy {policy_number} was not found"
        )

    monkeypatch.setattr(
        claim_main,
        "validate_policy",
        raise_policy_not_found,
    )

    response = client.post("/claims", json=valid_claim_payload())

    assert response.status_code == 422
    assert response.json()["detail"] == (
        "Policy POL-10001 was not found"
    )


def test_inactive_policy_blocks_claim(client, monkeypatch) -> None:
    def raise_policy_inactive(policy_number: str) -> None:
        raise PolicyInactiveError(
            f"Policy {policy_number} is not active"
        )

    monkeypatch.setattr(
        claim_main,
        "validate_policy",
        raise_policy_inactive,
    )

    response = client.post("/claims", json=valid_claim_payload())

    assert response.status_code == 422
    assert response.json()["detail"] == (
        "Policy POL-10001 is not active"
    )


def test_policy_service_failure_returns_503(
    client,
    monkeypatch,
) -> None:
    def raise_service_unavailable(policy_number: str) -> None:
        raise PolicyServiceUnavailableError(
            "Policy Service is temporarily unavailable"
        )

    monkeypatch.setattr(
        claim_main,
        "validate_policy",
        raise_service_unavailable,
    )

    response = client.post("/claims", json=valid_claim_payload())

    assert response.status_code == 503
    assert response.json()["detail"] == (
        "Policy Service is temporarily unavailable"
    )


def test_get_missing_claim_returns_404(client) -> None:
    response = client.get("/claims/not-found")

    assert response.status_code == 404
    assert response.json()["detail"] == "Claim not found"


def test_rejects_non_positive_amount(client) -> None:
    payload = valid_claim_payload()
    payload["estimated_amount"] = 0

    response = client.post("/claims", json=payload)

    assert response.status_code == 422
