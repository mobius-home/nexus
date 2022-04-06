defmodule NexusWeb.RequestParams.NewProductParams do
  @moduledoc """

  """

  @type t() :: %__MODULE__{
          name: binary()
        }

  defstruct [:name]

  defimpl NexusWeb.RequestParams do
    alias Ecto.Changeset

    def bind(new_product, %{"product" => params}) do
      types = %{name: :string}

      result =
        {%{}, types}
        |> Changeset.cast(params, [:name])
        |> Changeset.validate_required([:name])
        |> Changeset.apply_action(:insert)

      case result do
        {:ok, normalized} ->
          {:ok, %{new_product | name: normalized.name}}

        error ->
          error
      end
    end
  end
end
