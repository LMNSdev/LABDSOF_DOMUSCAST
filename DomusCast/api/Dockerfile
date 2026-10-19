FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# O processo corre sem privilégios de root
RUN useradd --system --no-create-home --uid 10001 appuser

COPY --chown=appuser:appuser . .

RUN chmod +x entrypoint.sh

USER appuser

EXPOSE 8000

CMD ["./entrypoint.sh"]
