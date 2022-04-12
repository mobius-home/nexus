defmodule NexusWeb.RequestParams.CreateUserParams do
  alias Nexus.Accounts.User

  @type t() :: %__MODULE__{
          first_name: User.first_name(),
          last_name: User.last_name(),
          email: User.email()
        }

  defstruct [:first_name, :last_name, :email]

  defimpl NexusWeb.RequestParams do
    alias Ecto.Changeset
    alias Nexus.Accounts.User

    def bind(user_params, %{"user" => params}) do
      types = %{first_name: :string, last_name: :string, email: :string}
      fields = Map.keys(types)

      result =
        {%{}, types}
        |> Changeset.cast(params, fields)
        |> Changeset.validate_required(fields)
        |> Changeset.apply_action(:insert)

      case result do
        {:ok, normalized} ->
          {:ok, struct!(user_params, normalized)}

        error ->
          error
      end
    end
  end
end
