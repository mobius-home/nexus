defmodule NexusWeb.Router do
  use NexusWeb, :router
  import NexusWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {NexusWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NexusWeb do
    pipe_through :browser

    live "/", RequestLoginLive
    post "/users/login", UserSessionController, :create_magic_link
    delete "/users/log-out", UserSessionController, :delete
  end

  scope "/", NexusWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/login/:token", UserSessionController, :create
  end

  scope "/", NexusWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/products", ProductsLive
    live "/products/new", ProductsLive, :add_product

    scope "/products" do
      live "/:product_slug", ProductLive

      live "/:product_slug/devices", ProductDevicesLive
      live "/:product_slug/devices/new", ProductDevicesLive, :add_device

      live "/:product_slug/metrics", ProductMetricsLive
      live "/:product_slug/metrics/new", ProductMetricsLive, :add_metric

      live "/:product_slug/devices/:device_slug", ProductDeviceLive
      live "/:product_slug/devices/:device_slug/metrics", ProductDeviceMetricsLive

      live "/:product_slug/devices/:device_slug/metrics/upload",
           ProductDeviceMetricsLive,
           :metric_upload
    end

    scope "/" do
      pipe_through [:require_admin_user]
      live "/users", ServerUsersLive
      live "/users/new", ServerUsersLive, :add_user
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", NexusWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: NexusWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
