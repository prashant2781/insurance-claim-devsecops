import os
from datetime import date
from enum import StrEnum

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field


class PolicyStatus(StrEnum):
    ACTIVE = "ACTIVE"
    EXPIRED = "EXPIRED"
    SUSPENDED = "SUSPENDED"
    CANCELLED = "CANCELLED"


class PolicyType(StrEnum):
    MOTOR = "MOTOR"
    HOME = "HOME"
    TRAVEL = "TRAVEL"
    HEALTH = "HEALTH"


class PolicyCreate(BaseModel):
    policy_number: str = Field(min_length=5, max_length=50)
    customer_name: str = Field(min_length=2, max_length=100)
    policy_type: PolicyType
    coverage_amount: float = Field(gt=0)
    premium_amount: float = Field(gt=0)
    start_date: date
    expiry_date: date
    status: PolicyStatus = PolicyStatus.ACTIVE


class Policy(PolicyCreate):
    pass


app = FastAPI(
    title="Insurance Policy Service",
    version="1.0.0",
    description="Manages insurance policy creation and retrieval.",
)

allowed_origins = [
    origin.strip()
    for origin in os.getenv("ALLOWED_ORIGINS", "").split(",")
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
)

policies: dict[str, Policy] = {}


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "healthy",
        "service": "insurance-policy-service",
    }


@app.post(
    "/policies",
    response_model=Policy,
    status_code=status.HTTP_201_CREATED,
)
def create_policy(policy_request: PolicyCreate) -> Policy:
    if policy_request.expiry_date <= policy_request.start_date:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Policy expiry date must be after the start date",
        )

    if policy_request.policy_number in policies:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Policy already exists",
        )

    policy = Policy(**policy_request.model_dump())
    policies[policy.policy_number] = policy

    return policy


@app.get("/policies/{policy_number}", response_model=Policy)
def get_policy(policy_number: str) -> Policy:
    policy = policies.get(policy_number)

    if policy is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Policy not found",
        )

    return policy
