defmodule Display.Repo do
  use Ecto.Repo,
    otp_app: :display,
    adapter: Ecto.Adapters.Postgres
end
