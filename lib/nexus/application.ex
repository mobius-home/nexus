defmodule Nexus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias InfluxEx.Client

  @impl true
  def start(_type, _args) do
    # Before starting anything lets make sure we are able to talk to
    # to the InfluxDB instance.
    :ok = ensure_influx_config()

    children = [
      Nexus.Repo,
      NexusWeb.Telemetry,
      {Phoenix.PubSub, name: Nexus.PubSub},
      NexusWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nexus.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NexusWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp ensure_influx_config() do
    case Application.get_env(:nexus, :influx) do
      nil ->
        raise ArgumentError, """
        You must configure your influx in the config for your env

        config :nexus, :influx,
          token: "devtoken",
          org: "my org"
        """

      config ->
        ensure_influx_org_id(config)
    end
  end

  # this will ensure the influx org id is available in the config
  defp ensure_influx_org_id(client_config) do
    if client_config[:org_id] do
      check_influx_server(client_config)
    else
      configure_influx_org_id(client_config)
    end
  end

  defp configure_influx_org_id(client_config) do
    client = make_client(client_config)

    case InfluxEx.Orgs.all(client, org: client.org) do
      {:ok, %{orgs: orgs}} ->
        [org] = orgs
        new_opts = Keyword.merge(client_config, org_id: org.id)
        Application.put_env(:nexus, :influx, new_opts)

      error ->
        raise_influx_server_error(error, client_config)
    end
  end

  defp check_influx_server(client_config) do
    client = make_client(client_config)

    case InfluxEx.health(client) do
      :ok ->
        :ok

      error ->
        raise_influx_server_error(error, client_config)
    end
  end

  defp make_client(client_config) do
    token = Keyword.fetch!(client_config, :token)
    org = Keyword.fetch!(client_config, :org)

    port = client_config[:port] || 8086
    host = client_config[:host] || "http://localhost"

    Client.new(token, port: port, host: host, org: org)
  end

  defp raise_influx_server_error(error, client_config) do
    raise RuntimeError, """
    Unable to resolve org id please ensure your Influx config is correct and
    instance is currently running.

    Config: #{inspect(client_config)}

    Error: #{inspect(error)}
    """
  end
end
