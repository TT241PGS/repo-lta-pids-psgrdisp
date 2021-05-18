defmodule Display.PredictionStatus do
  @moduledoc false
  import Ecto.Query, warn: false
  alias Display.Repo
  alias Display.PredictionStatus.PollerErrorLog

  # create
  def create_poller_error_log(reason) do
    %PollerErrorLog{}
    |> PollerErrorLog.changeset(%{
      rsn_txt: reason
    })
    |> Repo.insert()
  end
end
