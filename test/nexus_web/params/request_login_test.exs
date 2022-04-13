defmodule NexusWeb.Params.RequestLoginTest do
  use NexusWeb.RequestParamsCase, async: true

  alias Ecto.Changeset
  alias NexusWeb.Params
  alias NexusWeb.Params.RequestLogin

  test "when email is blank" do
    params = %{"request_login" => %{"email" => ""}}

    assert {:error, %Changeset{} = changeset} = Params.bind(%RequestLogin{}, params)

    assert "can't be blank" in errors_on(changeset).email
  end

  test "when email format is bad" do
    params = %{"request_login" => %{"email" => "helloworld"}}

    assert {:error, %Changeset{} = changeset} = Params.bind(%RequestLogin{}, params)

    assert "must have the @ sign and no spaces" in errors_on(changeset).email
  end

  test "when email is good" do
    params = %{"request_login" => %{"email" => "helloworld@test.com"}}

    assert {:ok, %RequestLogin{} = rl} = Params.bind(%RequestLogin{}, params)

    assert rl.email == "helloworld@test.com"
  end
end
