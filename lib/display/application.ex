defmodule Display.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Display.Repo,
      # Start redix
      Display.Redix,
      # Start the Telemetry supervisor
      DisplayWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Display.PubSub},
      # Start cachex
      {Cachex, name: :display},
      # Start the Endpoint (http/https)
      DisplayWeb.Endpoint,
      # Start a worker by calling: Display.Worker.start_link(arg)
      # {Display.Worker, arg}
      {Registry, keys: :unique, name: AdvisoryRegistry},
      # task supervisor for missing services logger
      {Task.Supervisor, name: Display.TaskSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Display.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DisplayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
