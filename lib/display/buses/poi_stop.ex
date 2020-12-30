defmodule Display.Buses.PoiStop do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "poi_stops" do
    field :stop_code, :integer
    field :stop_name, :string
    field :poi_type, :string
    field :poi_name, :string
    field :poi_pictogram, {:array, :string}
    field :poi_rank, :integer

    timestamps()
  end

  @field [
    :stop_code,
    :stop_name,
    :poi_type,
    :poi_name,
    :poi_pictogram,
    :poi_rank
  ]
  def changeset(poi_stop, params \\ %{}) do
    cast(poi_stop, params, @field)
  end
end
