defmodule Display.Templates.TemplateAssignment do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_cms_tmplt_asign" do
    field :bus_stop_group_id, :string, source: :bus_stop_grp_id_num
    field :bus_stop_panel_id, :string, source: :bus_stop_panel_id_num
    field :template_data_id, :string, source: :tmplt_data_id_num
    field :template_set_code, :string, source: :tmplt_set_cd_txt
  end

  @doc false
  def changeset(template_assignment, attrs) do
    template_assignment
    |> cast(attrs, [:bus_stop_panel_id, :template_set_code, :template_data_id, :bus_stop_group_id])
    |> validate_required([
      :bus_stop_panel_id,
      :template_set_code,
      :template_data_id,
      :bus_stop_group_id
    ])
  end
end
