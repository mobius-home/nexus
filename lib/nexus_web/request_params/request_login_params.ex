defmodule NexusWeb.RequestParams.RequestLoginParams do
  @moduledoc """

  """

  @type t() :: %__MODULE__{
          email: User.email()
        }

  defstruct email: nil

  defimpl NexusWeb.RequestParams do
    alias Ecto.Changeset

    @types %{email: :string}

    def bind(request_params, %{"login_request" => params}) do
      case changeset(params) do
        {:ok, normalized} ->
          {:ok, struct!(request_params, normalized)}

        error ->
          error
      end
    end

    def bind(_request_params, params) do
      changeset(params)
    end

    defp changeset(params) do
      {%{}, @types}
      |> Changeset.cast(params, [:email])
      |> Nexus.Accounts.validate_email()
      |> Changeset.apply_action(:insert)
    end
  end
end
