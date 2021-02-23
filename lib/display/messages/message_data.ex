defmodule Display.Messages.MessageData do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:message_data_id, :string, autogenerate: false, source: :msg_data_id_num}
  schema "pids_cms_msg_data" do
    field :name, :string, source: :nam_txt
    field :type, :string, source: :typ_txt
    field :priority, :integer, source: :prrty_num
    field :start_date_time, :naive_datetime, source: :srt_dttm
    field :end_date_time, :naive_datetime, source: :end_dttm
    field :start_time_1, :string, source: :srt_time_1_txt
    field :end_time_1, :string, source: :end_time_2_txt
    field :day_type_1, :boolean, source: :day_typ_1_ind
    field :day_type_2, :boolean, source: :day_typ_2_ind
    field :day_type_3, :boolean, source: :day_typ_3_ind
    field :message_content, :string, source: :msg_cntn_txt
  end

  @doc false
  def changeset(message_data, attrs) do
    message_data
    |> cast(attrs, [
      :name,
      :type,
      :priority,
      :start_date_time,
      :end_date_time,
      :start_time_1,
      :end_time_1,
      :day_type_1,
      :day_type_2,
      :day_type_3,
      :message_content
    ])
    |> validate_required([
      :type,
      :message_content
    ])
  end
end
