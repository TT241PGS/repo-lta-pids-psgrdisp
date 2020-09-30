defmodule DisplayWeb.NotificationController do
  @moduledoc false

  use DisplayWeb, :controller

  require Logger

  @doc false
  def create(
        conn,
        _
      ) do
    body = conn.body_params

    case body["event"] do
      "arrival_predictions_updated" ->
        DisplayWeb.Endpoint.broadcast!("poller", "arrival_predictions_updated", %{})
    end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, "OK")
  end
end
