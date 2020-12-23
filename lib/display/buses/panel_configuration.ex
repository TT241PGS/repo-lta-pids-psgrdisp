defmodule Display.Buses.PanelConfiguration do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "panel_configuration" do
    field :panel_id, :string
    field :day_group, :string
    field :night_group, :string
    field :service_group, :string
    field :service_group_type, :string
  end

  @field [
    :panel_id,
    :day_group,
    :night_group,
    :service_group,
    :service_group_type
  ]
  def changeset(panel_bus, params \\ %{}) do
    cast(panel_bus, params, @field)
  end
end
