# ASM-Hawk Python Workers
FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

CMD ["python", "-m", "rq.cli", "worker", "--url", "${REDIS_URL}"]
