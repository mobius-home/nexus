defmodule Nexus.Repo.Migrations.AddCreatedByFieldToTokens do
  use Ecto.Migration

  def change() do
    alter table("users_tokens") do
      add :created_by_id, references("users", on_delete: :delete_all)
    end
  end
end
