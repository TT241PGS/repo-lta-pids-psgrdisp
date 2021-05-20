defmodule Display.MissingServices do
  @moduledoc false
  import Ecto.Query, warn: false
  alias Display.Repo
  alias Display.MissingServices.MissingServicesLog

  # create
  def create_missing_services_log(error_type, reason, missing_service, bus_stop_no, operating_day) do
    %MissingServicesLog{}
    |> MissingServicesLog.changeset(%{
      err_typ_txt: error_type,
      rsn_txt: reason,
      msng_svcs_txt: missing_service,
      bus_stop_no_num: bus_stop_no,
      op_day_dt: operating_day
    })
    |> Repo.insert()
  end
end
