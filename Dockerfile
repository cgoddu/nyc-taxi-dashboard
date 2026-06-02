FROM python:3.12-slim

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir -r requirements.txt

RUN chmod +x scripts/docker-entrypoint.sh

EXPOSE 8501

CMD ["sh", "scripts/docker-entrypoint.sh"]