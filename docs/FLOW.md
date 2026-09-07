# Milestone 1 request flow

1. Client sends `POST /claims`.
2. FastAPI validates the JSON body through `ClaimCreate`.
3. The service generates a unique claim ID.
4. The claim is stored temporarily in an in-memory dictionary.
5. The API returns HTTP 201 with status `SUBMITTED`.
6. `GET /claims/{claim_id}` retrieves the stored claim.
7. `GET /health` is used later by Docker, ALB and ECS health checks.

## Ownership

- Developer: application code and unit tests.
- DevSecOps: pipeline automation, test execution, security gates, packaging and deployment.
- QA: functional, integration and regression validation.

The in-memory store is intentional for Milestone 1. A persistent database will be introduced later without mixing database complexity into the first CI/CD lesson.
