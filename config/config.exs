# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :display,
  ecto_repos: [Display.Repo]

# Configures the endpoint
config :display, DisplayWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "uuYw0MzXd7UWC5b3AYhZW+WrU4LZy1a6c5bs7am1k59wl2riCmWWbdzocef5F/2o",
  render_errors: [view: DisplayWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Display.PubSub,
  live_view: [signing_salt: "a63HA/vt"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
