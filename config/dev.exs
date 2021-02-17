use Mix.Config

# Husky
config :husky,
  # pre_commit: "mix format && mix credo --strict",
  # pre_push: "mix format --check-formatted && mix credo --strict && mix test",
  pre_commit: "mix format",
  pre_push: "mix format --check-formatted",
  json_codec: Jason

config :redix,
  host: System.fetch_env("REDIS_HOST"),
  port: System.fetch_env("REDIS_PORT")

config :display, Display.Repo,
  adapter: Ecto.Adapters.Postgres,
  hostname: System.fetch_env("POSTGRES_HOST"),
  port: System.fetch_env("POSTGRES_PORT"),
  database: System.fetch_env("POSTGRES_DB"),
  username: System.fetch_env("POSTGRES_USER"),
  password: System.fetch_env("POSTGRES_PASSWORD"),
  pool_size: System.fetch_env("POSTGRES_POOL_SIZE")

config :display,
  multimedia_base_url: System.fetch_env("MULTIMEDIA_BASE_URL")

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :display, DisplayWeb.Endpoint,
  http: [port: 5000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :display, DisplayWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/display_web/(live|views)/.*(ex)$",
      ~r"lib/display_web/templates/.*(eex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
