defmodule DisplayWeb.PanelRefreshController do
  @moduledoc false

  use DisplayWeb, :controller

  require Logger

  @doc false
  def handle(conn, %{"panel_id" => panel_id}) do
    Logger.info("Received request to refresh panel: " <> panel_id)

    DisplayWeb.Endpoint.broadcast!("poller", "refresh_panel", %{"panel_id" => panel_id})

    Logger.info("Broadcasted request to refresh panel: " <> panel_id)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, "OK")
  end
end
