defmodule Nexus.Devices.DeviceToken do
  @moduledoc """

  """

  use Ecto.Schema

  alias Nexus.Accounts.User
  alias Nexus.Devices.Device

  @type token() :: binary()

  @type t() :: %__MODULE__{
          token: token(),
          last_used: NaiveDateTime.t(),
          device: Device.t() | Ecto.Association.NotLoaded.t(),
          user: User.t() | Ecto.Association.NotLoaded.t()
        }

  schema "device_tokens" do
    field :token, :string
    field :last_used, :naive_datetime

    belongs_to :device, Device
    belongs_to :user, User

    timestamps([:inserted_at])
  end
end
