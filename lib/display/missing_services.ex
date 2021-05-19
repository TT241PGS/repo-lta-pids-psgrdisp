defmodule Display.MissingServices do
  @moduledoc false
  import Ecto.Query, warn: false
  alias Display.Repo
  alias Display.MissingServices.MissingServicesLog

  # create
  def create_missing_services_log(error_type, reason, missing_service, panel_id, operating_day) do
    %MissingServicesLog{}
    |> MissingServicesLog.changeset(%{
      err_typ_txt: error_type,
      rsn_txt: reason,
      msng_svc_txt: missing_service,
      panel_id_num: panel_id,
      op_day_txt: operating_day
    })
    |> Repo.insert()
  end
end
