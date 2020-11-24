defmodule PredictionsTwoColumn do
  @moduledoc false
  use Surface.LiveComponent

  property stopPredictionsRealtimeSet, :list, default: %{}
  property stopPredictionsScheduledSet, :list, default: %{}
  property realtimeActiveIndex, :integer, default: 0
  property scheduledActiveIndex, :integer, default: 0

  def render(assigns) do
    ~H"""
    <div class="predictions-wrapper">
      <PredictionsRealtimeTwoColumn :if={{ length(@stopPredictionsRealtimeSet) > 0 }} stopPredictionsSet={{@stopPredictionsRealtimeSet}} activeIndex={{@realtimeActiveIndex}}/>
      <PredictionsScheduledTwoColumn :if={{ length(@stopPredictionsRealtimeSet) <= 0 }} stopPredictionsSet={{@stopPredictionsScheduledSet}} activeIndex={{@scheduledActiveIndex}}/>
    </div>
    """
  end
end
