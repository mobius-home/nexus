# Nexus

Nexus is a centralized server for collecting IoT metric data for Elixir/Nerves
devices using [Mobius](https://hexdocs.pm/mobius/readme.html).

### ⚠️ Warning
This project is in the development stage. All APIs and UI may change without
warning and no guarantees are given about stability. Do not use it in
production. 

Nexus tries to keep the `ex_docs` updated and well organized, so run `mix docs`
to generate and see how to work with Nexus.

## Local setup

### System requirements

* Docker or Timescale DB
* Elixir 1.12+
* Erlang OTP 24+
* Elixir Phoenix 1.6+
* Node 17+

### Setup

#### Clone the repo

```bash
gh clone
```

#### Timescale DB

If you're using Docker you can use the provided `docker-compose.yml` file to up
and running quickly with Timescale DB by running:

```bash
docket-compose up -d
```

#### Elixir and phoenix

In the project directory run:

```bash
mix deps.get && mix ecto.setup && mix phx.server
```

For more information run `mix docs` and see the guides and API reference.
