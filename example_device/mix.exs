defmodule ExampleDevice.MixProject do
  use Mix.Project

  def project do
    [
      app: :example_device,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExampleDevice.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mobius, "~> 0.4.0"},
      {:telemetry_poller, "~> 1.0"},
      {:telemetry_metrics, "~> 0.6.0"},
      {:telemetry, "~> 1.0"}
    ]
  end
end
