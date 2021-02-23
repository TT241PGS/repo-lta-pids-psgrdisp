defmodule Display.Templates.TemplateData do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:template_data_id, :string, autogenerate: false, source: :orntn_txt}
  schema "pids_cms_tmplt_data" do
    field :orientation, :string, source: :orntn_txt
    field :requester, :string, source: :reqtr_txt
    field :template_detail, :string, source: :tmplt_dtl_txt
    field :template_name, :string, source: :tmplt_nam_txt
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
