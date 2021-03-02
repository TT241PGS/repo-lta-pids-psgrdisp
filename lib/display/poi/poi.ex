defmodule Display.Poi.Poi do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_poi" do
    field :code, :string, primary_key: true, source: :cd_txt
    field :name, :string, source: :nam_txt
    field :type, :string, source: :typ_txt
    field :rank, :integer, source: :rank_num
    field :pictogram_url, :string, source: :pictogram_url_txt
    field :effective_date, :utc_datetime, source: :eff_dt_dtmm

    timestamps(inserted_at_source: :crt_dttm, updated_at_source: :upd_dttm)
  end

  @field [
    :code,
    :name,
    :type,
    :rank,
    :pictogram_url,
    :effective_date
  ]
  def changeset(poi, params \\ %{}) do
    cast(poi, params, @field)
  end
end
