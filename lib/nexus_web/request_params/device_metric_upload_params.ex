defmodule NexusWeb.RequestParams.DeviceMetricUploadParams do
  @moduledoc """

  """

  @type t() :: %__MODULE__{
          target: Path.t(),
          source: Path.t()
        }

  defstruct [:target, :source]

  defimpl NexusWeb.RequestParams do
    alias Ecto.Changeset

    def bind(upload_params, %{"upload" => %{"filename" => params}}) do
      params = Map.from_struct(params) |> update_filename()
      types = %{target: :string, source: :string}
      fields = Map.keys(types)

      result =
        {%{}, types}
        |> Changeset.cast(params, fields)
        |> Changeset.validate_required(fields)
        |> Changeset.validate_format(:target, ~r/\w+\.mbf$/, message: "must be a mbf file")
        |> Changeset.apply_action(:insert)

      case result do
        {:ok, normalized} ->
          {:ok, %{upload_params | target: normalized.target, source: normalized.source}}

        error ->
          error
      end
    end

    defp update_filename(params) do
      dir = Path.dirname(params.path)
      path = Path.join(dir, params.filename)

      params
      |> Map.put(:target, path)
      |> Map.put(:source, params.path)
    end
  end
end
