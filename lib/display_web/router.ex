defmodule DisplayWeb.Router do
  use DisplayWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {DisplayWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  forward "/alive", HealthCheckup, resp_body: "I'm up!"

  scope "/", DisplayWeb do
    pipe_through :browser

    live "/", PageLive, :index
    live "/display", DisplayLive
  end

  scope "/api", DisplayWeb do
    pipe_through :api

    post "/notifications", NotificationController, :create
    post "/poller-prediction-errors", ErrorLogController, :handle
  end

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
      live_dashboard "/dashboard", metrics: DisplayWeb.Telemetry
    end
  end
end
