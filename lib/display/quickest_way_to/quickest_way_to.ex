defmodule Display.QuickestWayTo.QuickestWayTo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_quickest_way_to" do
    field :bus_stop_code, :integer, source: :bus_stop_cd_num
    field :sort_order, :integer, source: :sort_ordr_num
    field :poi_code, :string, source: :poi_cd_txt
    field :alternative_poi_display_name, :string, source: :alt_poi_disp_nam_txt
    field :alternative_text, :string, source: :alt_text_txt
    field :alternative_pictogram, {:array, :string}, source: :alt_pictogram_txt
    field :effective_date, :utc_datetime, source: :eff_dt_dttm

    timestamps(inserted_at_source: :crt_dttm, updated_at_source: :upd_dttm)
  end

  @field [
    :bus_stop_code,
    :sort_order,
    :poi_code,
    :alternative_poi_display_name,
    :alternative_text,
    :alternative_pictogram,
    :effective_date
  ]
  def changeset(pids_quickest_way_to, params \\ %{}) do
    cast(pids_quickest_way_to, params, @field)
  end
end
