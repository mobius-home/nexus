defmodule NexusWeb.Params do
  @moduledoc """
  Working with user params

  See [Towards Maintainable Elixir: The Core and the Interface](https://medium.com/very-big-things/towards-maintainable-elixir-the-core-and-the-interface-c267f0da43)
  for more information.
  """

  alias Ecto.Changeset

  @typedoc """
  A map of fields and their expected types
  """
  @type schema() :: map()

  @typedoc """
  Params that have been normalized against a schema
  """
  @type normalized_params() :: map()

  @doc """
  Normalize a loosely defined set of parameters into known data types
  """
  @spec normalize(schema(), map()) :: {:ok, normalized_params()} | {:error, Changeset.t()}
  def normalize(schema, params) do
    fields = Map.keys(schema)

    {%{}, schema}
    |> Changeset.cast(params, fields)
    |> Changeset.validate_required(fields)
    |> Changeset.apply_action(:insert)
  end

  @doc """
  Schema for params that contain the product slug field
  """
  @spec product_slug_schema() :: schema()
  def product_slug_schema() do
    %{product_slug: :string}
  end
end
