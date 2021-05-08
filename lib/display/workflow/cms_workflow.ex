defmodule Display.Workflow.CmsWorkflow do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_cms_wrkflw" do
    field :wrkflw_id_num, :string
    field :wrkflw_typ_txt, :string
    field :wrkflw_payload_txt, :string
  end

  @field [
    :wrkflw_id_num,
    :wrkflw_typ_txt,
    :wrkflw_payload_txt
  ]
  def changeset(pids_cms_wrkflw, params \\ %{}) do
    cast(pids_cms_wrkflw, params, @field)
  end
end
