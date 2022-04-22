defmodule Nexus.Products.DeviceToken do
  @moduledoc """

  """

  use Ecto.Schema

  alias Nexus.Accounts.User
  alias Nexus.Products.Device

  schema "device_tokens" do
    field :token, :string
    field :last_used, :naive_datetime

    belongs_to :device, Device
    belongs_to :user, User

    timestamps([:inserted_at])
  end
end
