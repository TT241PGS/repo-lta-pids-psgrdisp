defmodule Display.Messages.MessageAssignment do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_cms_msg_asign" do
    field :message_data_id, :string, source: :msg_data_id_num
    field :bus_stop_panel_id, :string, source: :bus_stop_panel_id_num
    field :bus_stop_group_id, :string, source: :bus_stop_grp_id_num
    field :bus_stop_id, :string, source: :bus_stop_id_num
    field :service_id, :string, source: :svc_id_num
  end

  @doc false
  def changeset(message_assignment, attrs) do
    message_assignment
    |> cast(attrs, [
      :message_data_id,
      :bus_stop_panel_id,
      :bus_stop_group_id,
      :bus_stop_id,
      :service_id
    ])
    |> validate_required([
      :message_data_id,
      :bus_stop_panel_id,
      :bus_stop_id
    ])
  end
end
