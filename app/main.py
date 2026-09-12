import os
from uuid import uuid4

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI(title="Insurance Claim Service", version="1.0.0")

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


class ClaimCreate(BaseModel):
    policy_number: str = Field(min_length=5, max_length=30)
    claimant_name: str = Field(min_length=2, max_length=100)
    claim_type: str = Field(min_length=3, max_length=50)
    estimated_amount: float = Field(gt=0, le=10_000_000)


class Claim(ClaimCreate):
    claim_id: str
    status: str = "SUBMITTED"


claims: dict[str, Claim] = {}


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "healthy", "service": "insurance-claim-service"}


@app.post("/claims", response_model=Claim, status_code=status.HTTP_201_CREATED)
def create_claim(request: ClaimCreate) -> Claim:
    claim = Claim(claim_id=str(uuid4()), **request.model_dump())
    claims[claim.claim_id] = claim
    return claim


@app.get("/claims/{claim_id}", response_model=Claim)
def get_claim(claim_id: str) -> Claim:
    claim = claims.get(claim_id)
    if claim is None:
        raise HTTPException(status_code=404, detail="Claim not found")
    return claim
