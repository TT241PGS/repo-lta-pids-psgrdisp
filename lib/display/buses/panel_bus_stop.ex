defmodule Display.Buses.PanelBusStop do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "panel_bus_stop" do
    field :panel_id, :string, primary_key: true
    field :bus_stop_code, :string
    field :point_no, :integer
    field :panel_type, :string
    field :area, :string
    field :desc, :string
    field :longitude, :float
    field :latitude, :float
    field :active, :boolean

    timestamps()
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
