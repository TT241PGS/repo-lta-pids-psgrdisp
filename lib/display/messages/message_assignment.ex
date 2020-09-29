defmodule Display.Messages.MessageAssignment do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "cms_message_assignment" do
    field :message_data_id, :string
    field :bus_stop_panel_id, :string
    field :bus_stop_group_id, :string
    field :bus_stop_id, :string
    field :service_id, :string
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
