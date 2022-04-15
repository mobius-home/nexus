defmodule NexusWeb.Params.NewDevice do
  @moduledoc """
  Params for creating a new device
  """

  alias Ecto.Changeset
  alias Nexus.Products.Device

  @types %{serial_number: :string}

  @typedoc """

  """
  @type t() :: %__MODULE__{
          serial_number: Device.serial_number()
        }

  defstruct [:serial_number]

  @doc """
  Create an empty changeset
  """
  @spec changeset() :: Changeset.t()
  def changeset() do
    {%__MODULE__{}, @types}
    |> Changeset.change(%{})
  end

  defimpl NexusWeb.Params do
    alias NexusWeb.Params.NewDevice

    def bind(_request_params, %{"new_device" => params}) do
      NewDevice.changeset()
      |> Changeset.cast(params, [:serial_number])
      |> Changeset.validate_required([:serial_number])
      |> Changeset.validate_length(:serial_number, max: 100)
      |> Changeset.apply_action(:insert)
    end
  end
end
