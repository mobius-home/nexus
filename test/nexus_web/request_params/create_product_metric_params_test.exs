defmodule NexusWeb.RequestParams.CreateProductMetricParamsTest do
  use NexusWeb.RequestParamsCase

  alias NexusWeb.RequestParams.CreateProductMetricParams

  test "when no metric fields are provided" do
    params = %{}

    assert {:error, changeset} = bind(%CreateProductMetricParams{}, params)

    assert "can't be blank" in errors_on(changeset).name
    assert "can't be blank" in errors_on(changeset).type
  end

  test "when type is not in counter or last_value" do
    params = %{"metric" => %{"type" => "sum", "name" => "a.b.c"}}

    assert {:error, changeset} = bind(%CreateProductMetricParams{}, params)

    assert "is invalid" in errors_on(changeset).type
  end

  test "when name is blank but there's a valid type" do
    params = %{"metric" => %{"type" => "counter", "name" => ""}}

    assert {:error, changeset} = bind(%CreateProductMetricParams{}, params)

    assert "can't be blank" in errors_on(changeset).name
  end

  test "when name is too long" do
    name = Enum.reduce(1..121, "", fn _, str -> str <> "A" end)
    params = %{"metric" => %{"type" => "counter", "name" => name}}

    assert {:error, changeset} = bind(%CreateProductMetricParams{}, params)

    assert "should be at most 120 character(s)" in errors_on(changeset).name
  end

  test "only when name is provided" do
    params = %{"metric" => %{"name" => "a.b.c", "type" => ""}}

    assert {:error, changeset} = bind(%CreateProductMetricParams{}, params)

    assert "can't be blank" in errors_on(changeset).type
  end

  test "when everything is okay" do
    params = %{"metric" => %{"type" => "last_value", "name" => "a.b.c"}}

    assert {:ok, %CreateProductMetricParams{} = ok_params} =
             bind(%CreateProductMetricParams{}, params)

    assert ok_params.type == "last_value"
    assert ok_params.name == "a.b.c"
  end
end
