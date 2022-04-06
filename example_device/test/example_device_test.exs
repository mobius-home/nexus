defmodule ExampleDeviceTest do
  use ExUnit.Case
  doctest ExampleDevice

  test "greets the world" do
    assert ExampleDevice.hello() == :world
  end
end
