defmodule NexusWeb.ProductSettingsLive do
  use NexusWeb, :surface_view

  alias Nexus.{Accounts, Products}
  alias Nexus.Products.Product
  alias NexusWeb.Components.{ProductViewContainer, ModalForm}
  alias NexusWeb.Components.Form.TextInput
  alias NexusWeb.{GetResourceLive, Params, Tokens}

  on_mount NexusWeb.UserLiveAuth
  on_mount {GetResourceLive, :product}

  def mount(_params, _session, socket) do
    token = Products.get_token(socket.assigns.product)

    socket =
      socket
      |> assign(:generated_token, nil)
      |> assign(:token, token)
      |> assign(:delete_product_errors, [])

    {:ok, socket}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def handle_event("generate-token", _params, socket) do
    case Accounts.create_product_token(
           socket.assigns.current_user,
           socket.assigns.product,
           &Tokens.product_token_signer/1
         ) do
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

  def handle_event("delete-product", _params, socket) do
    # this would probably be handle by AlpineJS better
    socket =
      push_patch(socket, to: Routes.product_settings_path(socket, :delete_product, socket.assigns.product.slug))

    {:noreply, socket}
  end

  def handle_event("confirm-delete", %{"delete_product" => params}, socket) do
    schema = [
      product_name: %{type: :string, required: true}
    ]

    with {:ok, normalized} <- Params.normalize(schema, params),
         :ok <- try_delete_product(normalized, socket) do
        {:noreply, push_redirect(socket, to: Routes.live_path(socket, NexusWeb.ProductsLive))}
         else
        {:error, socket} ->
          {:noreply, socket}
         end

  end

  defp try_delete_product(%{product_name: product_name}, %{assigns: %{product: %Product{name: product_name}}} = socket) do
    # above pattern match will ensure the provided product name and the actual
    # product name are the same
    case Products.delete_product_by_id(socket.assigns.product.id) do
      :ok ->
        :ok
    end
  end

  defp try_delete_product(_schema, socket) do
    errors =
      [product_name: {"name does not match", []}]

    {:error, assign(socket, :delete_product_errors, errors)}
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
        <h3 class="text-lg">Generate a new token</h3>
        <p class="text-sm mt-1 text-gray-600">
          You will only be shown the newly generated token once, be sure to copy it down somewhere safe
        </p>
        <button class="mt-4 border border-violet-300 rounded py-1 px-3" phx-click="generate-token">Generate token</button>
      {/if}

      <div class="mt-6">
        <h3 class="text-lg">Delete product</h3>
        <p class="text-sm mt-1 text-gray-600">
          Once you delete you product you will lose all data
        </p>
        <button
          class="mt-4 bg-red-200 border border-red-300 text-red-600 rounded py-1 px-3"
          phx-click="delete-product"
        >
          Delete product
        </button>
      </div>

      {#if @live_action == :delete_product}
        <ModalForm
         id={:delete_modal}
         title="Delete product"
         return_to={Routes.live_path(@socket, NexusWeb.ProductSettingsLive, @product.slug)}
         for={:delete_product}
         submit="confirm-delete"
         errors={@delete_product_errors}
        >
          <TextInput field_name={:product_name} placeholder="Product name" />
        </ModalForm>
      {/if}
    </ProductViewContainer>
    """
  end
end
