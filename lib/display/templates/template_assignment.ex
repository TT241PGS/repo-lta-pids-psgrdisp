defmodule Display.Templates.TemplateAssignment do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "cms_template_assignment" do
    field :bus_stop_group_id, :string
    field :bus_stop_panel_id, :string
    field :template_data_id, :string
    field :template_set_code, :string
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
