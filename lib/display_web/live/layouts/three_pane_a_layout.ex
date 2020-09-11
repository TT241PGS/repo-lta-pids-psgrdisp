defmodule ThreePaneALayout do
  @moduledoc false
  use Surface.LiveComponent

  property prop, :map, default: %{}

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-12 gap-4rem mb-4rem">
      <div class="col-span-7">
        <BusStopInfo busStopName={{@prop.bus_stop_name}} busStopNo={{@prop.bus_stop_no}} />
      </div>
      <div class="col-span-5">
        <DateTimeHorizontal />
      </div>
    </div>
    <PredictionsTwoColumn stopPredictions={{@prop.stop_predictions}} />
    """
  end
end