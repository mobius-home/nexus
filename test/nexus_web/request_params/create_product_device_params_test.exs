defmodule NexusWeb.RequestParams.CreateProductDeviceParamsTest do
  use ExUnit.Case, async: true

  alias NexusWeb.RequestParams
  alias NexusWeb.RequestParams.CreateProductDeviceParams

  test "when no serial number is provided" do
    params = %{"hello" => "world", "device" => %{"serial_number" => ""}}

    assert {:error, changeset} = RequestParams.bind(%CreateProductDeviceParams{}, params)

    assert {"can't be blank", [validation: :required]} ==
             Keyword.get(changeset.errors, :serial_number)
  end

  test "when no device field is present" do
    params = %{"hello" => "world"}

    assert {:error, changeset} = RequestParams.bind(%CreateProductDeviceParams{}, params)

    assert {"can't be blank", [validation: :required]} ==
             Keyword.get(changeset.errors, :serial_number)
  end

  test "when serial number is too long" do
    sn_number = Enum.reduce(1..101, "", fn _, str -> str <> "A" end)

    params = %{"device" => %{"serial_number" => sn_number}}

    assert {:error, changeset} = RequestParams.bind(%CreateProductDeviceParams{}, params)

    assert {"should be at most %{count} character(s)",
            [{:count, 100}, {:validation, :length}, {:kind, :max}, {:type, :string}]} ==
             Keyword.get(changeset.errors, :serial_number)
  end

  test "when everything is okay" do
    params = %{"device" => %{"serial_number" => "SN1234"}}

    assert {:ok, %CreateProductDeviceParams{} = ok_params} =
             RequestParams.bind(%CreateProductDeviceParams{}, params)

    assert ok_params.serial_number == "SN1234"
  end
end
