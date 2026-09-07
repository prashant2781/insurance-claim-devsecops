def valid_claim_payload():
    return {
        "policy_number": "POL-10001",
        "claimant_name": "Anita Sharma",
        "claim_type": "Vehicle Damage",
        "estimated_amount": 75000.0,
    }


def test_create_claim(client):
    response = client.post("/claims", json=valid_claim_payload())
    body = response.json()
    assert response.status_code == 201
    assert body["policy_number"] == "POL-10001"
    assert body["status"] == "SUBMITTED"
    assert body["claim_id"]


def test_get_existing_claim(client):
    created = client.post("/claims", json=valid_claim_payload()).json()
    response = client.get(f"/claims/{created['claim_id']}")
    assert response.status_code == 200
    assert response.json()["claim_id"] == created["claim_id"]


def test_get_missing_claim_returns_404(client):
    response = client.get("/claims/not-found")
    assert response.status_code == 404
    assert response.json()["detail"] == "Claim not found"


def test_rejects_non_positive_amount(client):
    payload = valid_claim_payload()
    payload["estimated_amount"] = 0
    response = client.post("/claims", json=payload)
    assert response.status_code == 422
