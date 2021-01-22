defmodule Display.Poi.PoiStop do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "poi_stops" do
    field :stop_code, :integer
    field :stop_name, :string
    field :poi_type, :string
    field :poi_name, :string
    field :poi_pictogram, :string
    field :poi_rank, :string
    field :poi_code, :string
    field :effective_date, :utc_datetime

    timestamps()
  end

  @field [
    :stop_code,
    :stop_name,
    :poi_type,
    :poi_name,
    :poi_pictogram,
    :poi_rank,
    :poi_code,
    :effective_date
  ]
  def changeset(poi_stop, params \\ %{}) do
    cast(poi_stop, params, @field)
  end
end
