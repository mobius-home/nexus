defmodule Nexus.Repo.Migrations.DevicesAddLastReportedAt do
  use Ecto.Migration

  def change() do
    alter table("devices") do
      add :last_reported_at, :naive_datetime
    end
  end
end
