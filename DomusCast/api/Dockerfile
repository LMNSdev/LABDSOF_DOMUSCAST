FROM python:3.15-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .

RUN apt-get update && \
    apt-get install -y gcc && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir -r requirements.txt

# O processo corre sem privilégios de root
RUN useradd --system --no-create-home --uid 10001 appuser

COPY --chown=appuser:appuser . .

RUN chmod +x entrypoint.sh

USER appuser

EXPOSE 8000

CMD ["./entrypoint.sh"]
