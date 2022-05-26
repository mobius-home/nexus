defmodule NexusWeb.API.DeviceMetricsController do
  @moduledoc """
  Controller for device metrics API
  """
  use NexusWeb, :controller

  alias Nexus.Devices
  alias Nexus.Devices.DeviceToken
  alias NexusWeb.Params

  def post_metrics(conn, params) do
    params_schema = [
      device_serial: %{type: :string, required: true},
      product_slug: %{type: :string, required: true}
    ]

    with {:ok, normalized} <- Params.normalize(params_schema, params),
         {:ok, token} <- get_token(conn),
         %DeviceToken{} <- Devices.get_device_token_by_token(token) do
      render(conn, "index.json")
    end
  end

  # move this to a plug at some point
  defp get_token(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      [] ->
        {:error, :missing_token}

      ["Bearer " <> token] ->
        {:ok, token}
    end
  end
end
