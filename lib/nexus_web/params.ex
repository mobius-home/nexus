defprotocol NexusWeb.Params do
  @moduledoc """
  Protocol for data structures to implement that allows unknown request params
  to be marshalled into a known structure.

  This should happen at the controller level as we don't want to leak the
  interface (the controller) concerns into the Nexus core library. The Nexus
  core API should be able to define it's API separate from the controller.

  Moreover, this will allow the known structure to check to ensure the interface
  params are correct.

  Yes this will require more code, however, this will help build a more
  maintainable software solution.

  For more information please see:
  https://medium.com/very-big-things/towards-maintainable-elixir-the-core-and-the-interface-c267f0da43

  Example implementation

  ```elixir
  defmodule UserProfileParams do
    @type t() :: %__MODULE__{
            first_name: binary(),
            last_name: binary(),
            age: integer(),
            email: binary() | nil
          }

    defstruct [:first_name, :last_name, :age, :email]

    defimpl NexusWeb.Params do
      alias Ecto.Changeset

      def bind(user_profile_params, params) do
        types = %{first_name: :string, last_name: :string, age: :integer, email: :string}

        {%{}, types}
        |> Changeset.cast(params, Map.keys(types))
        |> Changeset.validate_required(~w/first_name last_name age/)
        |> Changeset.apply_action(:insert)
        |> case do
          {:ok, normalized_params} ->
            {:ok,
             %{
               user_profile_params
               | first_name: normalized_params.first_name,
                 last_name: normalized_params.last_name,
                 age: normalized_params.age,
                 email: normalized_params.email
             }}

          error ->
            error
        end
      end
    end
  ```
  """

  alias Ecto.Changeset

  @doc """
  Try to bind the fields to the data structure
  """
  @spec bind(t(), map()) :: {:ok, t()} | {:error, Changeset.t()}
  def bind(t, map)
end
