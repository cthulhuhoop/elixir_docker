# elixir dev in docker

https://elixirforum.com/t/elixir-phoenix-running-a-dev-setup-inside-docker/43269

Elixir+Phoenix - running a dev setup inside docker
Phoenix Forum
Questions / Help
docker
docker-compose
phoenix
Oct 2021
Feb/2023

tommica

1
Oct/2021
I’m a complete noob when it comes to docker and docker compose, but I wanted to share my configuration to get a phoenix project up and running - I would really appreciate if someone could go through these and tell me what I am doing wrong (or missed, or something else) - I really want to learn to work with proper CI/CD tools

Dockerfile

FROM elixir:latest

EXPOSE 4000

RUN apt-get update && \
    apt-get install -y postgresql-client && \
    apt-get install -y inotify-tools && \
    apt-get install -y nodejs && \
    curl -L https://npmjs.org/install.sh | sh && \
    mix local.hex --force && \
    mix archive.install hex phx_new --force && \
    mix local.rebar --force

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
docker-compose.yml

version: "3"

services:
  phoenix:
    build: .
    volumes:
      - .:/app
    ports:
      - "4000:4000"
    environment:
      PGUSER: postgres
      PGPASSWORD: postgres
      PGDATABASE: myapp_dev
      PGHOST: db
      PGPORT: 5432
    depends_on:
      - db
    command:
      - "./entrypoint.sh"
  db:
    image: postgres:13.4-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      PGDATA: /var/lib/postgresql/data/pgdata
    restart: always
    volumes:
      - ./_pgdata:/var/lib/postgresql/data
entrypoint.sh (remember to make it executable by running chmod +x entrypoint.sh )

#!/bin/bash

set -e

# Ensure the app's dependencies are installed
mix deps.get

if [[ -f assets/package.json ]]; then
  # Install the app's dependencies with npm
  cd assets
  npm install
  cd ..
fi

# Wait until Postgres is ready
while ! pg_isready -q -h $PGHOST -p $PGPORT -U $PGUSER
do
  echo "$(date) - waiting for database to start"
  sleep 2
done

# Create, migrate, and seed database if it doesn't exist.
if [[ -z `psql -Atqc "\\list $PGDATABASE"` ]]; then
  echo "Database $PGDATABASE does not exist. Creating..."
  createdb -E UTF8 $PGDATABASE -l en_US.UTF-8 -T template0
  mix ecto.create
  mix ecto.migrate
  mix run priv/repo/seeds.exs
  echo "Database $PGDATABASE created."
fi

mix phx.server
.gitignore

...
# Ignore docker related files.
/_pgdata
config/dev.exs

username: System.get_env("PGUSER", "postgres"),
password: System.get_env("PGPASSWORD", "postgres"),
database: System.get_env("PGDATABASE", "myapp_dev"),
hostname: System.get_env("PGHOST", "localhost"),
port: String.to_integer(System.get_env("PGPORT", "5432")),
And finally again in config/dev.exs change this too (this is what stumped me for a while, and when I realized the issue, I felt like an idiot - by default phoenix binds to localhost only, so it is only binded to the port 4000 inside the VM, so no matter how much you expose port 4000 and forward it, it will not be accessible outside of docker, so curl localhost:4000 would just return an empty response):

http: [ip: {127, 0, 0, 1}, port: 4000],
to
http: [ip: {0, 0, 0, 0}, port: 4000],
Then just run docker-compose build and docker-compose up



