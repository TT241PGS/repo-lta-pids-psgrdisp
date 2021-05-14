defmodule Display.PredictionStatus do
  @moduledoc false
  import Ecto.Query, warn: false
  alias Display.Repo
  alias Display.PredictionStatus.PidsPredictionErrorLog

  # create
  def create_pids_prediction_error_log(reason, source, source_type) do
    %PidsPredictionErrorLog{}
    |> PidsPredictionErrorLog.changeset(%{
      rsn_txt: reason,
      src_txt: source,
      src_typ_txt: source_type
    })
    |> Repo.insert()
  end
end
