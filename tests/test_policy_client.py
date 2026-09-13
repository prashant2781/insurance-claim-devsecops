import httpx
import pytest

import app.policy_client as policy_client
from app.policy_client import (
    PolicyInactiveError,
    PolicyNotFoundError,
    PolicyServiceUnavailableError,
)

POLICY_URL = "http://policy-service"


def configure_mock_client(
    monkeypatch,
    handler,
) -> None:
    real_client = httpx.Client
    transport = httpx.MockTransport(handler)

    def client_factory(*args, **kwargs):
        return real_client(
            transport=transport,
            timeout=kwargs.get("timeout"),
        )

    monkeypatch.setattr(
        policy_client.httpx,
        "Client",
        client_factory,
    )


def test_validate_active_policy(monkeypatch) -> None:
    monkeypatch.setenv("POLICY_SERVICE_URL", POLICY_URL)

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            json={
                "policy_number": "POL-10001",
                "status": "ACTIVE",
            },
        )

    configure_mock_client(monkeypatch, handler)

    policy = policy_client.validate_policy("POL-10001")

    assert policy["status"] == "ACTIVE"


def test_missing_policy_service_url(monkeypatch) -> None:
    monkeypatch.delenv("POLICY_SERVICE_URL", raising=False)

    with pytest.raises(
        PolicyServiceUnavailableError,
        match="URL is not configured",
    ):
        policy_client.validate_policy("POL-10001")


def test_policy_not_found(monkeypatch) -> None:
    monkeypatch.setenv("POLICY_SERVICE_URL", POLICY_URL)

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(404, json={"detail": "Not found"})

    configure_mock_client(monkeypatch, handler)

    with pytest.raises(
        PolicyNotFoundError,
        match="POL-10001 was not found",
    ):
        policy_client.validate_policy("POL-10001")


def test_inactive_policy(monkeypatch) -> None:
    monkeypatch.setenv("POLICY_SERVICE_URL", POLICY_URL)

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            json={
                "policy_number": "POL-10001",
                "status": "SUSPENDED",
            },
        )

    configure_mock_client(monkeypatch, handler)

    with pytest.raises(
        PolicyInactiveError,
        match="POL-10001 is not active",
    ):
        policy_client.validate_policy("POL-10001")


def test_policy_server_error(monkeypatch) -> None:
    monkeypatch.setenv("POLICY_SERVICE_URL", POLICY_URL)

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(503)

    configure_mock_client(monkeypatch, handler)

    with pytest.raises(
        PolicyServiceUnavailableError,
        match="server error",
    ):
        policy_client.validate_policy("POL-10001")


def test_invalid_policy_response(monkeypatch) -> None:
    monkeypatch.setenv("POLICY_SERVICE_URL", POLICY_URL)

    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            content=b"not-json",
            headers={"Content-Type": "application/json"},
        )

    configure_mock_client(monkeypatch, handler)

    with pytest.raises(
        PolicyServiceUnavailableError,
        match="invalid response",
    ):
        policy_client.validate_policy("POL-10001")


def test_policy_connection_failure(monkeypatch) -> None:
    monkeypatch.setenv("POLICY_SERVICE_URL", POLICY_URL)

    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError(
            "Connection failed",
            request=request,
        )

    configure_mock_client(monkeypatch, handler)

    with pytest.raises(
        PolicyServiceUnavailableError,
        match="temporarily unavailable",
    ):
        policy_client.validate_policy("POL-10001")


def test_rejects_policy_number_path_traversal(monkeypatch) -> None:
    monkeypatch.setenv("POLICY_SERVICE_URL", POLICY_URL)

    with pytest.raises(
        PolicyNotFoundError,
        match="Policy number format is invalid",
    ):
        policy_client.validate_policy("../../health")
