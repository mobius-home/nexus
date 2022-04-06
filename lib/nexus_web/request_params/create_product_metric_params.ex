defmodule NexusWeb.RequestParams.CreateProductMetricParams do
  @moduledoc """
  Params for when creating a metric for a product
  """

  alias Ecto.Changeset

  defstruct [:name, :type]

  defimpl NexusWeb.RequestParams do
    @types %{name: :string, type: :string}

    @fields [:name, :type]

    def bind(new_product_metric_params, %{"metric" => params}) do
      case cast_validate_and_apply(params) do
        {:ok, normalized_params} ->
          {:ok, struct!(new_product_metric_params, normalized_params)}

        error ->
          error
      end
    end

    def bind(_, params) do
      cast_validate_and_apply(params)
    end

    def cast_validate_and_apply(params) do
      {%{}, @types}
      |> Changeset.cast(params, @fields)
      |> Changeset.validate_required(@fields)
      |> Changeset.validate_length(:name, min: 1, max: 120)
      |> Changeset.validate_inclusion(:type, ["last_value", "counter"])
      |> Changeset.apply_action(:insert)
    end
  end
end
