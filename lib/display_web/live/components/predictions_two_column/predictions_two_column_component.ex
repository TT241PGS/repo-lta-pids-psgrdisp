defmodule PredictionsTwoColumn do
  @moduledoc false
  use Surface.LiveComponent

  property stopPredictionsRealtimeSet, :list, default: %{}
  property stopPredictionsScheduledSet, :list, default: %{}

  def render(assigns) do
    ~H"""
    <div class="predictions-wrapper">
      <PredictionsRealtimeTwoColumn :if={{ length(@stopPredictionsRealtimeSet) > 0 }} stopPredictionsSet={{@stopPredictionsRealtimeSet}}/>
      <PredictionsScheduledTwoColumn :if={{ length(@stopPredictionsRealtimeSet) <= 0 }} stopPredictionsSet={{@stopPredictionsScheduledSet}}/>
    </div>
    """
  end
end
