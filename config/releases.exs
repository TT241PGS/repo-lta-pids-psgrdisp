import Config

config :display, DisplayWeb.Endpoint,
  http: [port: System.fetch_env!("API_PORT")],
  url: [host: System.fetch_env!("HOST"), port: System.fetch_env!("API_PORT")],
  server: true,
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

config :display,
  multimedia_base_url: System.fetch_env!("MULTIMEDIA_BASE_URL")

config :redix,
  host: System.fetch_env!("REDIS_HOST"),
  port: System.fetch_env!("REDIS_PORT")

config :display, Display.Repo,
  adapter: Ecto.Adapters.Postgres,
  hostname: System.fetch_env!("POSTGRES_HOST"),
  port: System.fetch_env!("POSTGRES_PORT"),
  database: System.fetch_env!("POSTGRES_DB"),
  username: System.fetch_env!("POSTGRES_USER"),
  password: System.fetch_env!("POSTGRES_PASSWORD"),
  pool_size: System.fetch_env!("POSTGRES_POOL_SIZE") |> String.to_integer()
