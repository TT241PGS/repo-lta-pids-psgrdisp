defmodule Display.Poi.Waypoint do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_waypoint" do
    field :base_version, :integer
    field :operating_day, :integer
    field(:cur_stop_no, :integer)
    field(:dpi_route_code, :string)
    field(:direction, :integer)
    field(:sequence_no, :integer)
    field(:poi_stop_no, :integer)
    field(:poi_stop_txt, :string)
    field(:poi_comnt_txt, :string)
    field(:org_code, :integer)
    field(:dest_code, :integer)
  end

  @field [
    :base_version,
    :operating_day,
    :cur_stop_no,
    :dpi_route_code,
    :direction,
    :sequence_no,
    :poi_stop_no,
    :poi_stop_txt,
    :poi_comnt_txt,
    :org_code,
    :dest_code
  ]
  def changeset(pids_waypoint, params \\ %{}) do
    cast(pids_waypoint, params, @field)
  end
end
