defmodule NexusWeb.RequestParams.CreateProductDeviceParams do
  @moduledoc """
  Request parameters for when creating a new device
  """

  @type t() :: %__MODULE__{
          serial_number: binary()
        }

  defstruct [:serial_number]

  defimpl NexusWeb.RequestParams do
    alias Ecto.Changeset

    @types %{serial_number: :string}

    @required_fields [:serial_number]

    def bind(new_device_params, %{"device" => device_params}) do
      result =
        {%{}, @types}
        |> Changeset.cast(device_params, @required_fields)
        |> apply_validations()

      case result do
        {:ok, normalized} ->
          {:ok, struct!(new_device_params, normalized)}

        error ->
          error
      end
    end

    def bind(_device_params, params) do
      {%{}, @types}
      |> Changeset.cast(params, @required_fields)
      |> apply_validations()
    end

    defp apply_validations(changeset) do
      changeset
      |> Changeset.validate_required(@required_fields)
      |> Changeset.validate_length(:serial_number, min: 1, max: 100)
      |> Changeset.apply_action(:insert)
    end
  end
end
