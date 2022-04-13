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
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.27", only: :docs, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ecto_timescaledb, "~> 0.10.0"},
      {:vega_lite, "~> 0.1.3"},
      {:surface, "~> 0.7.1"},
      {:surface_formatter, "~> 0.7.5"},
      {:mobius, "~> 0.4.0"}
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
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_extras: groups_for_extras(),
      assets: "guides/assets",
      groups_for_modules: [
        Core: [
          Nexus,
          Nexus.Accounts,
          Nexus.Products,
          Nexus.Products.MetricImports,
          Nexus.Repo,
          Nexus.Mailer
        ],
        Schemas: [
          Nexus.Accounts.User,
          Nexus.Accounts.UserToken,
          Nexus.Accounts.UserRole,
          Nexus.Accounts.UserMailer,
          Nexus.Products.Device,
          Nexus.Products.Label,
          Nexus.Products.Metric,
          Nexus.Products.Product,
          Nexus.Products.Metric.Upload,
          Nexus.Products.Metric.Measurement,
          Nexus.Products.Tag
        ],
        "Live Views": [
          NexusWeb.RequestLoginLive
        ],
        "Web Controllers": [
          NexusWeb.PageController,
          NexusWeb.ProductController,
          NexusWeb.ProductDeviceController,
          NexusWeb.ProductMetricController,
          NexusWeb.DeviceMetricController,
          NexusWeb.UserSessionController
        ],
        "Web Views": [
          NexusWeb.PageView,
          NexusWeb.ProductView,
          NexusWeb.ProductDeviceView,
          NexusWeb.ProductMetricView,
          NexusWeb.DeviceMetricView,
          NexusWeb.UserSessionView
        ],
        "Web Params": [
          NexusWeb.RequestParams,
          NexusWeb.Params,
          NexusWeb.Params.RequestLogin,
          NexusWeb.RequestParams.CreateProductDeviceParams,
          NexusWeb.RequestParams.CreateProductMetricParams,
          NexusWeb.RequestParams.GetProductDeviceParams,
          NexusWeb.RequestParams.MetricSlugParams,
          NexusWeb.RequestParams.NewProductParams,
          NexusWeb.RequestParams.ProductSlugParams,
          NexusWeb.RequestParams.DeviceMetricUploadParams,
          NexusWeb.RequestParams.TokenParams
        ],
        "Web Core": [
          NexusWeb,
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
