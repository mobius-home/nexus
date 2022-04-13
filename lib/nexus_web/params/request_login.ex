defmodule NexusWeb.Params.RequestLogin do
  @moduledoc """
  Params for requesting a login token
  """

  alias Ecto.Changeset
  alias Nexus.Accounts.User

  @types %{email: :string}

  @typedoc """

  """
  @type t() :: %__MODULE__{
          email: User.email()
        }

  defstruct [:email]

  @doc """
  Create an empty changeset
  """
  @spec changeset() :: Changeset.t()
  def changeset() do
    {%NexusWeb.Params.RequestLogin{}, @types}
    |> Changeset.change(%{})
  end

  defimpl NexusWeb.Params do
    alias NexusWeb.Params.RequestLogin

    def bind(_request_params, %{"request_login" => params}) do
      RequestLogin.changeset()
      |> Changeset.cast(params, [:email])
      |> Nexus.Accounts.validate_email()
      |> Changeset.apply_action(:insert)
    end
  end
end
