defmodule NexusWeb.RequestParams.GetProductDeviceParams do
  @moduledoc """

  """

  alias Ecto.Changeset
  alias Nexus.Products.Device

  @type t() :: %__MODULE__{
          device_slug: Device.slug()
        }

  defstruct [:device_slug]

  defimpl NexusWeb.RequestParams do
    def bind(device_params, params) do
      types = %{device_slug: :string}
      fields = Map.keys(types)

      result =
        {%{}, types}
        |> Changeset.cast(params, fields)
        |> Changeset.validate_required(fields)
        |> Changeset.apply_action(:insert)

      case result do
        {:ok, normalized_params} ->
          {:ok, struct!(device_params, normalized_params)}

        error ->
          error
      end
    end
  end
end
