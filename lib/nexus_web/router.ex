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

  pipeline :product do
    plug NexusWeb.Plugs.GetProduct
  end

  pipeline :device do
    plug NexusWeb.Plugs.GetDevice
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

    get "/products", ProductController, :index
    post "/products", ProductController, :create
    get "/products/new", ProductController, :new

    scope "/products" do
      pipe_through [:product]

      get "/:product_slug", ProductController, :show

      post "/:product_slug/devices", ProductDeviceController, :create
      get "/:product_slug/devices/new", ProductDeviceController, :new

      get "/:product_slug/metrics/new", ProductMetricController, :new
      post "/:product_slug/metrics", ProductMetricController, :create
      get "/:product_slug/metrics/:metric_slug", ProductMetricController, :show

      scope "/:product_slug/devices" do
        pipe_through [:device]
        get "/:device_slug", ProductDeviceController, :show

        get "/:device_slug/metrics/upload", DeviceMetricController, :new_upload
        post "/:device_slug/metrics/upload", DeviceMetricController, :upload
        get "/:device_slug/metrics/:metric_slug", DeviceMetricController, :show
      end
    end

    scope "/" do
      pipe_through [:require_admin_user]
      get "/users", ServerUserController, :index
      post "/users", ServerUserController, :create
      get "/users/new", ServerUserController, :new
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
