.PHONY: install test lint run

install:
	python -m pip install -r requirements-dev.txt

test:
	python -m pytest

lint:
	python -m ruff check .

run:
	python -m uvicorn app.main:app --reload --port 8080
