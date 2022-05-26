defmodule NexusWeb.ProductSettingsLive do
  use NexusWeb, :surface_view

  alias Nexus.{Accounts, Products}
  alias NexusWeb.Components.ProductViewContainer
  alias NexusWeb.GetResourceLive

  on_mount NexusWeb.UserLiveAuth
  on_mount {GetResourceLive, :product}

  def mount(_params, _session, socket) do
    token = Products.get_token(socket.assigns.product)

    socket =
      socket
      |> assign(:generated_token, nil)
      |> assign(:token, token)

    {:ok, socket}
  end

  def handle_event("generate-token", _params, socket) do
    case Accounts.create_product_token(socket.assigns.current_user, socket.assigns.product) do
      {:ok, token} ->
        socket =
          socket
          |> assign(:generated_token, token)
          |> assign(:token, token)

        {:noreply, socket}
    end
  end

  def handle_event("revoke-token", _params, socket) do
    {:ok, _deleted} = Products.delete_token(socket.assigns.token)

    socket =
      socket
      |> assign(:token, nil)
      |> assign(:generated_token, nil)

    {:noreply, socket}
  end

  def handle_event("close-token-banner", _params, socket) do
    # this would be handled by AlpineJS better
    socket =
      socket
      |> assign(:generated_token, nil)

    {:noreply, socket}
  end

  defp get_token_creator(token) do
    Accounts.user_full_name(token.creator)
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
    <ProductViewContainer product={@product} socket={@socket} page={:settings}>
      {#if @generated_token}
        <div class="bg-violet-100 rounded pt-2 pb-4 px-4 mb-4">
          <div class="flex justify-end">
            <p class="cursor-pointer ml-4" phx-click="close-token-banner">&times;</p>
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
              <td class="p-4">{get_token_creator(@token)}</td>
              <td class="p-4 text-red-400 cursor-pointer hover:text-red-600"><p phx-click="revoke-token">Revoke</p></td>
            </tr>
          </tbody>
        </table>
      {#else}
        <button phx-click="generate-token">Generate token</button>
      {/if}
    </ProductViewContainer>
    """
  end
end
