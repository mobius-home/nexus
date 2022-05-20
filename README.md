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

* Docker or PosgreSQL and InfluxDB
* Elixir 1.12+
* Erlang OTP 24+
* Elixir Phoenix 1.6+
* Node 17+

### Setup

#### Clone the repo

```bash
gh clone
```

#### Databases

If you're using Docker you can use the provided `docker-compose.yml` file to up
and running quickly with the databases by running:

```bash
docker-compose up -d
```

By default `config/dev.exs` is configured to work with the docker configuration.
If you want to provide your own instances of either Postgres or InfluxDB you
will to set the appropriate configuration values in your config file.

To configure InfluxDB you are required to configure the token and org:

```elixir
config :nexus, :influx, token: "mytoken", org: "myorg"
```

If you do not provide at minium those fields Nexus wont start.

Other configuration fields for Infux are: `:port`, `:host`, and `:org_id`.

The `:org_id` is required to talk to some InfluxDB API endpoints, so if you do
not provide that configuration parameter Nexus will try to resolve that on
start.

#### Elixir and phoenix

In the project directory run:

```bash
mix deps.get && mix ecto.setup && mix phx.server
```

For more information run `mix docs` and see the guides and API reference.
