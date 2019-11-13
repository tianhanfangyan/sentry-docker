#!/usr/bin/env bash

# redis
docker run \
  --detach \
  --name sentry-redis \
  redis

# postgres
docker run \
  --detach \
  --name sentry-postgres \
  --env POSTGRES_PASSWORD=secret \
  --env POSTGRES_USER=sentry \
  postgres

# sentry
docker pull sentry

# get secret-key
secret_key=`docker run --rm sentry config generate-secret-key`

# configure
docker run \
  -it \
  --rm \
  -e SENTRY_SECRET_KEY=${secret_key} \
  --link sentry-postgres:postgres \
  --link sentry-redis:redis \
  sentry upgrade

# web
docker run \
  --detach \
  -p 9000:9000 \
  --name my-sentry \
  -e SENTRY_SECRET_KEY=${secret_key} \
  --link sentry-redis:redis \
  --link sentry-postgres:postgres \
  sentry

# cron
docker run \
  --detach \
  --name sentry-cron \
  -e SENTRY_SECRET_KEY=${secret_key} \
  --link sentry-postgres:postgres \
  --link sentry-redis:redis \
  sentry run cron

# worker
docker run \
  --detach \
  --name sentry-worker-1 \
  -e SENTRY_SECRET_KEY=${secret_key} \
  --link sentry-postgres:postgres \
  --link sentry-redis:redis
  sentry run worker
