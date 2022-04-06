defmodule Nexus.Repo.Migrations.CreateTagsTable do
  use Ecto.Migration

  def change() do
    create table("tags") do
      add :key, :string, null: false
      add :value, :string, null: false
    end

    create unique_index("tags", [:key, :value])
  end
end
