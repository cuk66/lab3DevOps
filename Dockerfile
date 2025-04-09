# Этап сборки
FROM python:3.10-alpine AS builder

RUN apk add --no-cache gcc musl-dev libpq-dev

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY ./app /app

RUN python manage.py collectstatic --noinput

# Этап выполнения
FROM python:3.10-alpine

RUN apk add --no-cache libpq && \
    addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /usr/local /usr/local
COPY --from=builder /app /app

RUN chown -R appuser:appgroup /app

EXPOSE 8000

USER appuser

ENTRYPOINT ["sh", "-c"]

CMD ["python manage.py migrate && \
      python manage.py shell -c 'from django.contrib.auth import get_user_model; \
      User = get_user_model(); \
      User.objects.filter(username=\"admin\").exists() or \
      User.objects.create_superuser(\"admin\", \"admin@example.com\", \"admin\")' && \
      python manage.py runserver 0.0.0.0:8000"]





