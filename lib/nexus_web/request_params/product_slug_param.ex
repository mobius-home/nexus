defmodule NexusWeb.RequestParams.ProductSlugParams do
  @moduledoc """

  """

  alias Ecto.Changeset

  @type t() :: %__MODULE__{
          product_slug: binary()
        }

  defstruct [:product_slug]

  defimpl NexusWeb.RequestParams do
    def bind(slug_params, params) do
      types = %{product_slug: :string}

      result =
        {%{}, types}
        |> Changeset.cast(params, [:product_slug])
        |> Changeset.validate_required([:product_slug])
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
