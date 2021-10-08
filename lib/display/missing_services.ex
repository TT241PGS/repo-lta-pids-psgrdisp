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

  # read
  def read_missing_services_log(missing_services, operating_day, bus_stop_no) do
    query =
      from ms in MissingServicesLog,
        where:
          ms.msng_svcs_txt == ^missing_services and
            ms.op_day_dt == ^operating_day and
            ms.bus_stop_no_num == ^bus_stop_no

    Repo.exists?(query)
  end
end
