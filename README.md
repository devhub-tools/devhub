# Devhub

![coverbot](https://img.shields.io/endpoint?url=https://private.devhub.cloud/coverbot/v1/devhub-tools/devhub/main/badge.json)

## Setup

Run docker compose to start the database and other services:

```bash
docker compose up -d
```

Fetch Elixir dependenices and setup the database:

```bash
mix setup
```

Next, install Phoenix's JavaScript dependencies:

```bash
$ npm i --prefix assets
```

## Starting the Server

To start your Phoenix server:

- Start services with `docker compose up -d`
- Start Phoenix endpoint with `mix phx.server` or inside IEx with
  `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Storybook
When in `dev`, it is possible to browse our component in Storybook (work in progress).
In order to do so, go to `http://localhost:4000/storybook`.