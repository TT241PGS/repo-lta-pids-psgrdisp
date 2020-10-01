defmodule Display.Messages.MessageData do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:message_data_id, :string, autogenerate: false}
  schema "cms_message_data" do
    field :name, :string
    field :type, :string
    field :priority, :string
    field :start_date_time, :naive_datetime
    field :end_date_time, :naive_datetime
    field :start_time_1, :string
    field :end_time_1, :string
    field :day_type_1, :boolean
    field :day_type_2, :boolean
    field :day_type_3, :boolean
    field :message_content, :string
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