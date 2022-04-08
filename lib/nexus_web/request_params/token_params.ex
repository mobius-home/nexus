defmodule NexusWeb.RequestParams.TokenParams do
  @moduledoc """

  """

  alias Nexus.Accounts

  @type t() :: %__MODULE__{
          token: Accounts.login_token()
        }

  defstruct token: nil

  defimpl NexusWeb.RequestParams do
    alias Ecto.Changeset

    def bind(token_params, params) do
      types = %{token: :string}

      result =
        {%{}, types}
        |> Changeset.cast(params, [:token])
        |> Changeset.validate_required([:token])
        |> Changeset.apply_action(:insert)

      case result do
        {:ok, normalized} ->
          {:ok, struct!(token_params, normalized)}

        error ->
          error
      end
    end
  end
end
