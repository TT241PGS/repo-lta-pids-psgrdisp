defmodule Display.Buses.BusStop do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_stop" do
    field :base_version, :integer, primary_key: true
    field :point_type, :integer, primary_key: true
    field :point_no, :integer, primary_key: true
    field :point_desc, :string
    field :stop_no, :integer
    field :stop_type, :integer
    field :stop_long_no, :integer
    field :stop_abbr, :string
    field :stop_desc, :string
    field :zone_cell_no, :integer
    field :point_longitude, :float
    field :point_latitude, :float
    field :point_elevation, :integer
    field :point_heading, :integer
    field :stop_no_local, :integer
    field :stop_no_national, :integer
    field :stop_no_international, :string

    timestamps()
  end

  @field [
    :base_version,
    :point_type,
    :point_no,
    :point_desc,
    :stop_no,
    :stop_type,
    :stop_long_no,
    :stop_abbr,
    :stop_desc,
    :zone_cell_no,
    :point_longitude,
    :point_latitude,
    :point_elevation,
    :point_heading,
    :stop_no_local,
    :stop_no_national,
    :stop_no_international
  ]
  def changeset(stop, params \\ %{}) do
    cast(stop, params, @field)
  end
end
