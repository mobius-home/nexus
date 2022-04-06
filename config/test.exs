import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :nexus, Nexus.Repo,
  username: "db",
  password: "db",
  hostname: "localhost",
  database: "db",
  port: 5592,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :nexus, NexusWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ZIMqsgSYrPsi6USHsv2SrXhlmcnOCupqbNFOHAWJ9Fv5YpGZF58BMJC08RCQpgdT",
  server: false

# In test we don't send emails.
config :nexus, Nexus.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
