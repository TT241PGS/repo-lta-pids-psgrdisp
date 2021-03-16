defmodule PredictionsLandscape do
  @moduledoc false
  use Surface.LiveComponent

  property stopPredictionsRealtimeSet, :list, default: %{}
  property stopPredictionsScheduledSet, :list, default: %{}
  property realtimeActiveIndex, :integer, default: 0
  property scheduledActiveIndex, :integer, default: 0

  property suppressed_messages, :map,
    default: %{global_message: nil, service_message_map: nil, hide_services: []}

  property twoColumn, :boolean, default: false
  property is_bushub, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div class="buses">
      <PredictionsRealtimeLandscape :if={{ length(@stopPredictionsRealtimeSet) > 0 and is_nil(@suppressed_messages.global_message) }} stopPredictionsSet={{@stopPredictionsRealtimeSet}} activeIndex={{@realtimeActiveIndex}} suppressed_messages={{@suppressed_messages}} twoColumn={{@twoColumn}} is_bushub={{@is_bushub}}/>
      <PredictionsScheduledLandscape :if={{ length(@stopPredictionsRealtimeSet) <= 0 and is_nil(@suppressed_messages.global_message) }} stopPredictionsSet={{@stopPredictionsScheduledSet}} activeIndex={{@scheduledActiveIndex}} suppressed_messages={{@suppressed_messages}} twoColumn={{@twoColumn}} is_bushub={{@is_bushub}}/>
      <div style="min-height: 1460px; color: white; display: flex; align-items: center; justify-content: center" :if={{ @suppressed_messages.global_message != nil }}>
        <h1>{{@suppressed_messages.global_message}}</h1>
      </div>
    </div>
    """
  end
end
