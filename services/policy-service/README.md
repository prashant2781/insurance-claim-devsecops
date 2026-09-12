# Insurance Policy Service

Independent FastAPI microservice for insurance policy management.

## Endpoints

- GET /health
- POST /policies
- GET /policies/{policy_number}

## Current storage

Policy records are temporarily stored in process memory. Persistent database storage will be added in a later milestone.

## Container port

The application listens on container port 8000.
