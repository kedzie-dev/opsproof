FROM python:3.13-slim

WORKDIR /app

COPY pyproject.toml ./
COPY src ./src

RUN pip install --no-cache-dir .

ENV PYTHONUNBUFFERED=1
ENV PORT=8000

CMD ["opentelemetry-instrument", "uvicorn", "--factory", "opsproof.api:create_app", "--host", "0.0.0.0", "--port", "8000"]
