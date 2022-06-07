defmodule Nexus.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :nexus,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers() ++ [:surface],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      preferred_cli_env: [docs: :docs]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Nexus.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.17.5"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:esbuild, "~> 0.3", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:surface, "~> 0.7.1"},
      {:mobius, "~> 0.5.0"},
      {:influx_ex, "~> 0.2.1"},
      {:req, "~> 0.2.2"},
      {:nimble_csv, "~> 1.0"},
      # Dev deps
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.27", only: :docs, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "run priv/repo/test_seeds.exs",
        "test"
      ],
      "assets.deploy": [
        "cmd --cd assets npm run deploy",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end

  defp docs() do
    [
      extras: ["README.md", "CHANGELOG.md", "CONTRIBUTING.md", "guides/UsingNexusLocally.md"],
      main: "readme",
      extra_section: "GUIDES",
      source_ref: "v#{@version}",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md", "CONTRIBUTING.md"],
      groups_for_extras: groups_for_extras(),
      assets: "guides/assets",
      groups_for_modules: [
        Core: [
          Nexus.Accounts,
          Nexus.Products,
          Nexus.Devices,
          Nexus.Products.MetricImports,
          Nexus.Repo,
          Nexus.Mailer
        ],
        Schemas: [
          Nexus.Accounts.User,
          Nexus.Accounts.UserToken,
          Nexus.Accounts.UserRole,
          Nexus.Accounts.UserMailer,
          Nexus.Device,
          Nexus.Product,
          Nexus.ProductSettings
        ],
        "Live Views": [
          NexusWeb.RequestLoginLive,
          NexusWeb.ProductDeviceDataLive,
          NexusWeb.ProductDeviceLive,
          NexusWeb.ProductDeviceSettingsLive,
          NexusWeb.ProductDevicesLive,
          NexusWeb.ProductLive,
          NexusWeb.ProductMeasurementsLive,
          NexusWeb.ProductsLive,
          NexusWeb.ServerUsersLive
        ],
        Components: [
          NexusWeb.Components.DeviceViewContainer,
          NexusWeb.Components.ProductViewContainer,
          NexusWeb.Components.Form,
          NexusWeb.Components.Modal,
          NexusWeb.Components.ModalForm,
          NexusWeb.Components.Form.TextInput
        ],
        "Live Plugs": [
          NexusWeb.GetResourceLive,
          NexusWeb.UserLiveAuth
        ],
        "Web Controllers": [
          NexusWeb.UserSessionController
        ],
        "Web Views": [
          NexusWeb.UserSessionView
        ],
        "Web Core": [
          NexusWeb,
          NexusWeb.Params,
          NexusWeb.UserAuth,
          NexusWeb.Endpoint,
          NexusWeb.ErrorHelpers,
          NexusWeb.ErrorView,
          NexusWeb.Gettext,
          NexusWeb.LayoutView,
          NexusWeb.Router,
          NexusWeb.Router.Helpers
        ],
        "Web Plugs": [
          NexusWeb.Plugs.GetProductMetic,
          NexusWeb.Plugs.GetProduct,
          NexusWeb.Plugs.GetDevice,
          NexusWeb.Plugs.GetDeviceMetric
        ]
      ]
    ]
  end

  defp groups_for_extras do
    [
      Nexus: ~r/guides\/.?/
    ]
  end
end
