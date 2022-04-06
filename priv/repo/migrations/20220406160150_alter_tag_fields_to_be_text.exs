defmodule Nexus.Repo.Migrations.AlterTagFieldsToBeText do
  use Ecto.Migration

  def change() do
    alter table("tags") do
      modify :key, :text
      modify :value, :text
    end
  end
end
