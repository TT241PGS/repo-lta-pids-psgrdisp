defmodule DisplayWeb.ErrorLogController do
  @moduledoc """
  Accepts API POST request from poller for error logging
  """
  use DisplayWeb, :controller

  alias Display.PredictionStatus

  def handle(conn, params) do

    PredictionStatus.create_pids_prediction_error_log(params["error"], "poller", "poller")

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: true}))
  end
end
