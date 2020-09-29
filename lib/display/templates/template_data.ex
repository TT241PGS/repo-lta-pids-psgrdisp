defmodule Display.Templates.TemplateData do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:template_data_id, :string, autogenerate: false}
  schema "cms_template_data" do
    field :orientation, :string
    field :requester, :string
    field :template_detail, :string
    field :template_name, :string
  end

  @doc false
  def changeset(template_data, attrs) do
    template_data
    |> cast(attrs, [:template_data_id, :template_name, :template_detail, :orientation, :requester])
    |> validate_required([
      :template_data_id,
      :template_name,
      :template_detail,
      :orientation,
      :requester
    ])
  end
end
