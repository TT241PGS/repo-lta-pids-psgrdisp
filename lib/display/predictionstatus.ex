defmodule Display.PredictionStatus do
  @moduledoc false
  import Ecto.Query, warn: false
  alias Display.Repo
  alias Display.PredictionStatus.PidsPredictionErrorLog

  # create
  def create_pids_prediction_error_log(reason, source, source_type) do
    %PidsPredictionErrorLog{}
    |> PidsPredictionErrorLog.changeset(%{
      reason: reason,
      source: source,
      source_type: source_type
    })
    |> Repo.insert()
  end
end
