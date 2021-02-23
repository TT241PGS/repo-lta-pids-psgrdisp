defmodule Display.Poi.PoiStop do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_poi_stops" do
    field :stop_code, :integer, source: :stop_cd_num
    field :stop_name, :string, source: :stop_nam_txt
    field :poi_type, :string, source: :poi_typ_txt
    field :poi_name, :string, source: :poi_nam_txt
    field :poi_pictogram, :string, source: :poi_pictogram_txt
    field :poi_rank, :string, source: :poi_rank_num
    field :poi_code, :string, source: :poi_cd_txt
    field :effective_date, :utc_datetime, source: :eff_dt_dttm

    timestamps(inserted_at_source: :insert_at_dttm, updated_at_source: :upd_at_dttm)
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
