FROM python:3.13-slim

# Liga a imagem publicada no GHCR a este repositório
LABEL org.opencontainers.image.source="https://github.com/LMNSdev/LABDSOF_DOMUSCAST"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .

# upgrade: aplica as correções de segurança do Debian que ainda não estão na imagem base
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y gcc && \
    rm -rf /var/lib/apt/lists/*

# O pip só é preciso no build; sai da imagem final com as dependências que traz consigo
RUN pip install --no-cache-dir -r requirements.txt && \
    pip uninstall -y pip

# O processo corre sem privilégios de root
RUN useradd --system --no-create-home --uid 10001 appuser
RUN mkdir -p /app/media && chown appuser:appuser /app/media

COPY --chown=appuser:appuser . .

RUN chmod +x entrypoint.sh

USER appuser

EXPOSE 8000

CMD ["./entrypoint.sh"]
