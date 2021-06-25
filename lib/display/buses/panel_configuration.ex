defmodule Display.Buses.PanelConfiguration do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_panel_cnfig" do
    field :panel_id, :string, source: :panel_id_num
    field :service_group, :string, source: :svc_grp_txt
    field :service_group_type, :string, source: :svc_grp_typ_txt
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
