defmodule Display.Buses.PanelBus do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "panel_bus" do
    field :base_version, :integer
    field :panel_id, :string
    field :bus_stop_no, :integer

    timestamps()
  end

  @field [
    :id,
    :base_version,
    :panel_id,
    :bus_stop_no
  ]
  def changeset(panel_bus, params \\ %{}) do
    cast(panel_bus, params, @field)
  end
end
