defmodule NexusWeb.RequestParams.MetricSlugParams do
  @moduledoc """
  Params for binding a metric slug param
  """

  alias Ecto.Changeset
  alias Nexus.Products.Metric

  @type t() :: %__MODULE__{
          metric_slug: Metric.slug()
        }

  defstruct [:metric_slug]

  defimpl NexusWeb.RequestParams do
    def bind(slug_params, params) do
      types = %{metric_slug: :string}

      result =
        {%{}, types}
        |> Changeset.cast(params, [:metric_slug])
        |> Changeset.validate_required([:metric_slug])
        |> Changeset.apply_action(:insert)

      case result do
        {:ok, normalized} ->
          {:ok, struct!(slug_params, normalized)}

        error ->
          error
      end
    end
  end
end
