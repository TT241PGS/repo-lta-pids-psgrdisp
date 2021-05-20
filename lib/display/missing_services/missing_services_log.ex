defmodule Display.MissingServices.MissingServicesLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id_uuid, Ecto.UUID, autogenerate: true}

  schema "pids_miss_svc_log" do
    field :err_typ_txt, :string
    field :rsn_txt, :string
    field :msng_svcs_txt, {:array, :string}, default: []
    field :bus_stop_no_num, :integer
    field :op_day_dt, :date

    timestamps(inserted_at_source: :crt_dttm, updated_at_source: :upd_dttm)
  end

  @doc false
  def changeset(pids_miss_svc_log, attrs) do
    pids_miss_svc_log
    |> cast(attrs, [:rsn_txt, :err_typ_txt, :msng_svcs_txt, :bus_stop_no_num, :op_day_dt])
    |> validate_required([:rsn_txt, :err_typ_txt, :msng_svcs_txt, :bus_stop_no_num, :op_day_dt])
  end
end
