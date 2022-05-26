defmodule Nexus.Repo.Migrations.CreateProductToken do
  use Ecto.Migration

  def change do
    create table("product_tokens") do
      add :token, :string, null: false
      add :product_id, references("products", on_delete: :delete_all), null: false
      add :creator_id, references("users"), null: false
      add :last_used, :naive_datetime

      timestamps([:inserted_at])
    end

    create unique_index("product_tokens", [:product_id])
  end
end
