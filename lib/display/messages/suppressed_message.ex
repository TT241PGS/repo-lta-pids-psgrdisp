defmodule Display.Messages.SuppressedMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_suppressed_msg" do
    field :stop_code, :integer, source: :stop_cd_num
    field :service_nos, {:array, :string}, source: :svc_nos_txt
    field :start_date_time, :naive_datetime, source: :str_dt_tm_dttm
    field :end_date_time, :naive_datetime, source: :end_dt_tm_dttm
    field :start_time_1, :string, source: :str_tm_1_txt
    field :end_time_1, :string, source: :end_tm_1_txt
    field :day_type_1, :boolean, source: :day_typ_1_ind
    field :day_type_2, :boolean, source: :day_typ_2_ind
    field :day_type_3, :boolean, source: :day_typ_3_ind
    field :show_service, :boolean, source: :show_sev_ind
    field :message_to_display, :string, source: :msg_to_disp_txt
    field :lta_comment, :string, source: :lta_comnt_txt
    field :use_rule, :boolean, source: :use_rule_ind

    timestamps(inserted_at_source: :insert_at_dttm, updated_at_source: :upd_at_dttm)
  end

  @field [
    :stop_code,
    :service_nos,
    :start_date_time,
    :end_date_time,
    :start_time_1,
    :end_time_1,
    :day_type_1,
    :day_type_2,
    :day_type_3,
    :show_service,
    :message_to_display,
    :lta_comment,
    :use_rule
  ]
  def changeset(suppressed_message, params \\ %{}) do
    cast(suppressed_message, params, @field)
  end
end
