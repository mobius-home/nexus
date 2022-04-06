defmodule Nexus.Validations do
  @moduledoc false

  ## Helper changeset validations

  alias Ecto.Changeset

  @doc """
  Validate a fields of the changeset that will be used to identify items in the
  database

  This is a general validation and other format validation might need to take
  place after this basic validation.
  """
  @spec validate_database_identity_name(Changeset.t(), atom()) :: Changeset.t()
  def validate_database_identity_name(changeset, field) do
    name = Changeset.get_change(changeset, field)
    not_allowed = ~r/#|!|@|&|\^|\*|\)|\(|\+|=|\?|}|{|>|<|\.|\/|~|`|%|\"|\'|\n|\||\\|\:|;/

    if !Regex.match?(not_allowed, name) do
      changeset
    else
      Changeset.add_error(changeset, :name, "special characters are not allowed in name")
    end
  end
end
