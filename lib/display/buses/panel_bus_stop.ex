defmodule Display.Buses.PanelBusStop do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_panel_bus_stop" do
    field :panel_id, :string, primary_key: true, source: :panel_id_num
    field :bus_stop_code, :string, source: :bus_stop_cd_txt
    field :point_no, :integer, source: :pt_no_num
    field :panel_type, :string, source: :panel_typ_txt
    field :area, :string, source: :area_txt
    field :desc, :string, source: :desc_txt
    field :longitude, :float, source: :longtd_num
    field :latitude, :float, source: :lattd_num

    timestamps(inserted_at_source: :crt_dttm, updated_at_source: :upd_dttm)
  end

  @field [
    :base_version,
    :panel_id,
    :bus_stop_code,
    :point_no,
    :panel_type,
    :area,
    :desc,
    :longitude,
    :latitude,
    :active
  ]
  def changeset(panel_bus_stop, params \\ %{}) do
    cast(panel_bus_stop, params, @field)
  end
end
