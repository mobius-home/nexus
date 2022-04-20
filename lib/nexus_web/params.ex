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
  @type schema() :: map() | keyword()

  @typedoc """
  Params that have been normalized against a schema
  """
  @type normalized_params() :: map()

  @doc """
  Normalize a loosely defined set of parameters into known data types
  """
  @spec normalize(schema(), map()) :: {:ok, normalized_params()} | {:error, Changeset.t()}
  def normalize(schema, params) when is_list(schema) do
    normalized_schema =
      Enum.reduce(schema, %{types: %{}, required: []}, fn {field_name, field_info},
                                                          parsed_schema ->
        new_types = Map.put(parsed_schema.types, field_name, field_info.type)

        if required?(field_info) do
          new_required = [field_name | parsed_schema.required]
          %{parsed_schema | types: new_types, required: new_required}
        else
          %{parsed_schema | types: new_types}
        end
      end)

    {%{}, normalized_schema.types}
    |> Changeset.cast(params, Map.keys(normalized_schema.types))
    |> Changeset.validate_required(normalized_schema.required)
    |> Changeset.apply_action(:insert)
  end

  def normalize(schema, params) do
    fields = Map.keys(schema)

    {%{}, schema}
    |> Changeset.cast(params, fields)
    |> Changeset.validate_required(fields)
    |> Changeset.apply_action(:insert)
  end

  defp required?(field_info) do
    Map.get(field_info, :required) || false
  end

  @doc """
  Schema for params that contain the product slug field
  """
  @spec product_slug_schema() :: schema()
  def product_slug_schema() do
    %{product_slug: :string}
  end
end
