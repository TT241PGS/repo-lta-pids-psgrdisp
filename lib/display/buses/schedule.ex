defmodule Display.Buses.Schedule do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_schedule" do
    field :base_version, :integer
    field :line_no, :integer
    field :route_abbr, :string
    field :direction, :integer
    field :dest_code, :integer
    field :no_of_stops, :integer
    field :sequence_no, :integer
    field :point_no, :integer
    field :point_type, :integer
    field :arriving_time, :integer
    field :departure_time, :integer
    field :day_type_no, :integer
    field :dpi_route_code, :string

    timestamps()
  end

  @field [
    :base_version,
    :operating_day_desc,
    :line_no,
    :route_abbr,
    :direction,
    :dest_code,
    :no_of_stops,
    :sequence_no,
    :point_no,
    :point_type,
    :arriving_time,
    :departure_time,
    :day_type_no,
    :dpi_route_code
  ]
  def changeset(bus_schedule, params \\ %{}) do
    cast(bus_schedule, params, @field)
  end
end
