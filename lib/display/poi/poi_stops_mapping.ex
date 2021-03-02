defmodule Display.Poi.PoiStopsMapping do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_poi_stops_map" do
    field :point_no, :integer, primary_key: true, source: :pt_no_num
    field :poi_code, :string, primary_key: true, source: :poi_cd_txt
    field :comments, :string, source: :comnt_txt

    timestamps(inserted_at_source: :crt_dttm, updated_at_source: :upd_dttm)
  end

  @field [
    :point_no,
    :poi_code,
    :comments
  ]
  def changeset(poi_stops_mapping, params \\ %{}) do
    cast(poi_stops_mapping, params, @field)
  end
end
