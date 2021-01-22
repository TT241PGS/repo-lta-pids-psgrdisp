defmodule Display.Buses.BushubInterchange do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "bushub_interchange_mapping" do
    field :point_no, :integer
    field :dpi_route_code, :string
    field :direction, :integer
    field :visit_no, :integer
    field :berth_label, :string
    field :destination, :string
    field :way_points, :string
    field :lta_comment, :string
    field :stop_name, :string

    timestamps()
  end

  @field [
    :point_no,
    :dpi_route_code,
    :direction,
    :berth_label,
    :destination,
    :way_points,
    :lta_comment,
    :stop_name,
    :visit_no
  ]
  def changeset(bushub_interchange, params \\ %{}) do
    cast(bushub_interchange, params, @field)
  end
end
