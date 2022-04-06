defmodule ExampleDevice.Application do
  use Application

  alias Telemetry.Metrics

  @impl Application
  def start(_type, _args) do
    metrics = [
      Metrics.last_value("vm.memory.total")
    ]

    children = [
      {Mobius, metrics: metrics, persistence_dir: "/tmp"}
    ]

    opts = [strategy: :one_for_one, name: ExampleDevice.Application]
    Supervisor.start_link(children, opts)
  end
end
