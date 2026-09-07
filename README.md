# Insurance Claim Service - DevSecOps Practical

This repository is the base microservice for a production-style CI/CD and DevSecOps learning project.

## Is this a microservice?

Yes. It is an independently buildable and deployable Claim Service with its own API and health endpoint. In Milestone 1 it uses an in-memory store so the request and test flow remains clear. Persistence and service integrations are added later.

## Endpoints

- `GET /health`
- `POST /claims`
- `GET /claims/{claim_id}`

## Run locally

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-dev.txt
python -m uvicorn app.main:app --reload --port 8080
```

Open `http://localhost:8080/docs` for Swagger UI.

## Run developer checks

```bash
python -m ruff check .
python -m pytest
```

## Docker

```bash
docker build -t insurance-claim-service:local .
docker run --rm -p 8080:8080 insurance-claim-service:local
```

## Current milestone

Milestone 1 establishes the deployable service, developer-owned unit tests, a coverage gate, lint configuration, a non-root Docker image and a health endpoint. Security pipeline files are intentionally added milestone by milestone so every control is understood before automation.

## Planned security path

PR validation will later include code quality, unit tests, coverage, secret scanning, SAST, SCA and IaC scanning. Release validation will add SBOM generation, container scanning, ECR/Inspector, DEV deployment, DAST, QA promotion, production approval, monitoring and rollback.
