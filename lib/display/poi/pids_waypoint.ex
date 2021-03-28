defmodule Display.Poi.Waypoint do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_waypoint" do
    field :cur_stop_no, :integer
    field :dpi_route_code, :string
    field :direction, :integer
    field :poi_stop_no, :integer
    field :poi_stop_txt, :string
    field :poi_comnt_txt, :string
  end

  @field [
    :cur_stop_no,
    :dpi_route_code,
    :direction,
    :poi_stop_no,
    :poi_stop_txt,
    :poi_comnt_txt
  ]
  def changeset(pids_waypoint, params \\ %{}) do
    cast(pids_waypoint, params, @field)
  end
end
