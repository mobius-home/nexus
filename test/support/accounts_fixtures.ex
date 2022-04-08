defmodule Nexus.Test.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating entities via the `Toss.Accounts`
  context.
  """

  alias Nexus.Accounts

  @some_names [
    "Blue",
    "Cheese",
    "Buffalo",
    "Wings",
    "Tofu",
    "Rice",
    "Carrot",
    "Colby",
    "Jack",
    "Pepper",
    "Coffee",
    "Green",
    "Tea",
    "Eggs",
    "Sweet",
    "Potatoes"
  ]

  def unique_user_email, do: "user#{System.unique_integer()}@nexustest.com"
  def generate_name(), do: Enum.random(@some_names)

  def user_fixture(opts \\ []) do
    {:ok, user} = Accounts.add_user(unique_user_email(), generate_name(), generate_name(), opts)
    user
  end

  def user_fixture_with_name(name) do
    [first, last | _] = String.split(name, " ", trim: true)

    Accounts.add_user(unique_user_email(), first, last)
  end
end
