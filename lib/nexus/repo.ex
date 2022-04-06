defmodule Nexus.Repo do
  use Ecto.Repo,
    otp_app: :nexus,
    adapter: Ecto.Adapters.Postgres
end
