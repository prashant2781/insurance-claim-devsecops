import os

import httpx


class PolicyNotFoundError(Exception):
    pass


class PolicyInactiveError(Exception):
    pass


class PolicyServiceUnavailableError(Exception):
    pass


def validate_policy(policy_number: str) -> dict:
    policy_service_url = os.getenv("POLICY_SERVICE_URL", "").rstrip("/")

    if not policy_service_url:
        raise PolicyServiceUnavailableError(
            "Policy Service URL is not configured"
        )

    policy_url = f"{policy_service_url}/policies/{policy_number}"

    timeout = httpx.Timeout(
        connect=2.0,
        read=3.0,
        write=3.0,
        pool=2.0,
    )

    try:
        with httpx.Client(timeout=timeout) as client:
            response = client.get(policy_url)

    except (
        httpx.ConnectError,
        httpx.ConnectTimeout,
        httpx.ReadTimeout,
    ) as error:
        raise PolicyServiceUnavailableError(
            "Policy Service is temporarily unavailable"
        ) from error

    if response.status_code == 404:
        raise PolicyNotFoundError(
            f"Policy {policy_number} was not found"
        )

    if response.status_code >= 500:
        raise PolicyServiceUnavailableError(
            "Policy Service returned a server error"
        )

    try:
        response.raise_for_status()
        policy = response.json()
    except (httpx.HTTPStatusError, ValueError) as error:
        raise PolicyServiceUnavailableError(
            "Policy Service returned an invalid response"
        ) from error

    if policy.get("status") != "ACTIVE":
        raise PolicyInactiveError(
            f"Policy {policy_number} is not active"
        )

    return policy
