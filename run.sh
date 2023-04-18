docker-compose exec redash ./manage.py database create_tables
docker compose down && docker compose build && docker compose up
