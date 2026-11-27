#!/bin/sh
set -e
echo "Running Alembic migrations..."
alembic upgrade head
echo "Starting API..."
# --no-access-log: o access log do uvicorn regista a query string (que pode ter tokens);
# a linha JSON por pedido vem do middleware de app/observabilidade.py (T-07).
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --no-access-log
