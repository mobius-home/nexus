defmodule Nexus.Slug do
  @moduledoc false

  @doc """
  Make slug from the string
  """
  @spec make_slug(binary()) :: binary()
  def make_slug(str) do
    str
    |> String.replace(~r/\s|_|\./, "-")
    |> String.downcase()
  end
end
