defmodule Nexus.Repo.Migrations.OnDeviceDeleteRemoveAllTokens do
  use Ecto.Migration

  def change do
    alter table("device_tokens") do
      modify :device_id, references("devices", on_delete: :delete_all),
        null: false,
        from: references("products")
    end
  end
end
