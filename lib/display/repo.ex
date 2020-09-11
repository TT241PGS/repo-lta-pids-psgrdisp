defmodule Display.Repo do
  use Ecto.Repo,
    otp_app: :display,
    adapter: Ecto.Adapters.Postgres

  def init(_, opts) do
    {:ok, build_opts(opts)}
  end

  defp build_opts(opts) do
    system_opts = [
      hostname: System.get_env("POSTGRES_HOST"),
      port: System.get_env("POSTGRES_PORT"),
      database: System.get_env("POSTGRES_DB"),
      password: System.get_env("POSTGRES_PASSWORD"),
      username: System.get_env("POSTGRES_USER"),
      pool_size: System.get_env("POSTGRES_POOL_SIZE") |> String.to_integer()
    ]

    Keyword.merge(opts, system_opts)
  end
end
