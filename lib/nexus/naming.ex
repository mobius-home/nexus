defmodule Nexus.Naming do
  @moduledoc false

  ## Helpers on generating system names

  @type opt() :: {:prefix, binary()} | {:postfix, binary()}

  @doc """
  Create a slug from an entity name
  """
  @spec make_slug_from_name(binary(), binary(), binary()) :: binary()
  def make_slug_from_name(name, prefix \\ "", postfix \\ "") do
    name = prefix <> name <> postfix

    name
    |> String.replace(~r/\s|_|\./, "-")
    |> String.downcase()
  end

  @doc """
  Create a database identifier from an entity name
  """
  @spec make_database_identifier_from_name(binary(), [opt()]) :: binary()
  def make_database_identifier_from_name(name, opts \\ []) do
    prefix = opts[:prefix] || ""
    postfix = opts[:postfix] || ""

    name = prefix <> name <> postfix

    name
    |> String.replace(~r/\s|-|\./, "_")
    |> String.downcase()
  end
end
