defmodule ExampleDevice do
  @moduledoc """
  An example device
  """

  @doc """
  Export the Mobius metrics to your system's `tmp` directory
  """
  def export() do
    Mobius.Exports.mbf(out_dir: "/tmp")
  end

  @doc """
  This should simulate when a device shuts down for know reason

  On graceful shutdown Mobius can record the metrics to restore for them next
  time. So, if we stop this device by calling `shutdown/0` the next time we run
  this device Mobius will restore the old metrics and continue tracking them.
  """
  def shutdown() do
    :init.stop()
  end
end
