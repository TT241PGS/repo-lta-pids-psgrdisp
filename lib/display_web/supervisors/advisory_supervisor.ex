defmodule AdvisorySupervisor do
  use DynamicSupervisor

  def start_link(panel_id),
    do: DynamicSupervisor.start_link(__MODULE__, panel_id, name: __MODULE__)

  def init(_panel_id),
    do: DynamicSupervisor.init(strategy: :one_for_one)

  def start(panel_id) do
    DynamicSupervisor.start_child(__MODULE__, {AdvisoryPoller, panel_id})
    DynamicSupervisor.start_child(__MODULE__, {AdvisoryTimelineGenerator, panel_id})
    DynamicSupervisor.start_child(__MODULE__, {AdvisoryTimelinePlayer, panel_id})
  end
end
