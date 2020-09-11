use Mix.Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.

config :display, DisplayWeb.Endpoint,
  http: [port: "${API_PORT}"],
  url: [host: "${HOST}", port: "${API_PORT}"],
  server: true,
  secret_key_base: "${SECRET_KEY_BASE}"

config :display,
  datamall_base_url: "${DATAMALL_BASE_URL}",
  datamall_account_key: "${DATAMALL_ACCOUNT_KEY}"

config :redix,
  host: "${REDIS_HOST}",
  port: "${REDIS_PORT}"

# Do not print debug messages in production
config :logger, level: :info
