defmodule Display.Messages.SuppressedMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "suppressed_message" do
    field :stop_code, :string
    field :service_nos, {:array, :string}
    field :start_date_time, :naive_datetime
    field :end_date_time, :naive_datetime
    field :start_time_1, :string
    field :end_time_1, :string
    field :day_type_1, :boolean
    field :day_type_2, :boolean
    field :day_type_3, :boolean
    field :show_service, :boolean
    field :message_to_display, :string
    field :lta_comment, :string
    field :use_rule, :boolean

    timestamps()
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
