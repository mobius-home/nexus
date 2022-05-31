defmodule NexusWeb.API.DeviceMetricsController do
  @moduledoc """
  Controller for device metrics API
  """
  use NexusWeb, :controller

  alias Nexus.{Products, Devices}
  alias Nexus.Devices.Device
  alias NexusWeb.{Params, Tokens}

  def post_metrics(conn, %{"metrics" => metrics} = params) do
    params_schema = [
      device_serial: %{type: :string, required: true},
      product_slug: %{type: :string, required: true}
    ]

    metrics = :erlang.list_to_binary(metrics)

    with {:ok, normalized} <- Params.normalize(params_schema, params),
         {:ok, token} <- get_token(conn),
         {:ok, product} <-
           Products.verity_token_and_fetch_product(
             normalized.product_slug,
             token,
             &Tokens.verify_product_token/1
           ),
         %Device{} = device <- Devices.get_device_by_serial_number(normalized.device_serial),
         _ <-
           Devices.import_metrics(device, metrics, product, type: :mbf_binary) do
      render(conn, "index.json")
    else
      {:error, :missing_token} ->
        conn
        |> put_status(401)
        |> halt()
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
