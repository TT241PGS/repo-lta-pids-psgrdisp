defmodule Display.Buses.PanelAudioLevelConfiguration do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_panel_cnfig" do
    field :panel_id, :string, source: :panel_id_num
    field :audio_lvl, :string, source: :audio_lvl_txt
    field :audio_enable_str_tm, :time, source: :audio_enable_str_tm
    field :audio_enable_end_tm, :time, source: :audio_enable_end_tm
  end

  @field [
    :panel_id,
    :audio_lvl,
    :audio_enable_str_tm,
    :audio_enable_end_tm,
  ]
  def changeset(panel_bus, params \\ %{}) do
    cast(panel_bus, params, @field)
  end
end
