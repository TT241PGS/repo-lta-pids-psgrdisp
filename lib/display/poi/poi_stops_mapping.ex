defmodule Display.Poi.PoiStopsMapping do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "poi_stops_mapping" do
    field :point_no, :integer, primary_key: true
    field :poi_code, :string, primary_key: true
    field :comments, :string

    timestamps()
  end

  @field [
    :point_no,
    :poi_code,
    :comments,
  ]
  def changeset(poi_stops_mapping, params \\ %{}) do
    cast(poi_stops_mapping, params, @field)
  end
end
