defmodule NexusWeb.ProductDeviceSettingsLive do
  @moduledoc """

  """

  use NexusWeb, :surface_view

  alias Nexus.Accounts
  alias Nexus.Accounts.User
  alias Nexus.Products
  alias NexusWeb.Components.DeviceViewContainer

  on_mount NexusWeb.UserLiveAuth
  on_mount {NexusWeb.GetResourceLive, [:product, :device]}

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:generated_token, nil)
      |> assign(:token, Products.get_token_for_device(socket.assigns.device))

    {:ok, socket}
  end

  def handle_event("gen-token", _params, socket) do
    {:ok, token} =
      Products.create_token_for_device(socket.assigns.device, socket.assigns.current_user)

    socket =
      socket
      |> assign(:generated_token, token)
      |> assign(:token, token)

    {:noreply, socket}
  end

  def handle_event("revoke-token", _params, socket) do
    :ok = Products.revoke_token_for_device(socket.assigns.device)
    socket = assign(socket, :token, nil)

    {:noreply, socket}
  end

  def handle_event("remove-generated-token-banner", _params, socket) do
    socket = assign(socket, :generated_token, nil)
    {:noreply, socket}
  end

  defp get_token_creator(token, current_user) do
    case token.user do
      %User{} = user -> Accounts.user_full_name(user)
      _ -> Accounts.user_full_name(current_user)
    end
  end

  defp format_token(token) do
    last_six =
      token.token
      |> String.split_at(-6)
      |> elem(1)

    "XXXXXXXXXXXX-#{last_six}"
  end

  def render(assigns) do
    ~F"""
    <DeviceViewContainer
      socket={@socket}
      page={:settings}
      product_slug={@product.slug}
      device={@device}
      product_name={@product.name}
    >
      {#if @generated_token}
        <div class="bg-violet-100 rounded pt-2 pb-4 px-4 mb-4">
          <div class="flex justify-end">
            <p class="cursor-pointer ml-4" phx-click="remove-generated-token-banner">&times;</p>
          </div>
          <p class="font-bold mb-2 text-center">New Access Token:</p>
          <p class="mb-2 text-center">{@generated_token.token}</p>
          <p class="text-center">This token will never be visible again so you should copy it now!</p>
        </div>
      {/if}

      {#if @token}
        <table class="table-auto w-full">
          <thead>
            <tr>
              <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Token</th>
              <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600">Created by</th>
              <th class="text-left border-b-2 font-medium text-sm p-4 pb-2 text-gray-600" />
            </tr>
          </thead>
          <tbody>
            <tr class="even:bg-gray-100 font-light text-gray-500">
              <td class="p-4">{format_token(@token)}</td>
              <td class="p-4">{get_token_creator(@token, @current_user)}</td>
              <td class="p-4 text-red-400 cursor-pointer hover:text-red-600"><p phx-click="revoke-token">Revoke</p></td>
            </tr>
          </tbody>
        </table>
      {#else}
        <button phx-click="gen-token">Gen token</button>
      {/if}
    </DeviceViewContainer>
    """
  end
end
