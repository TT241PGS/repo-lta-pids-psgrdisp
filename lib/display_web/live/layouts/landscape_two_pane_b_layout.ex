defmodule LandscapeTwoPaneBLayout do
  @moduledoc false
  use Surface.LiveComponent

  property(prop, :map, default: %{})

  def render(assigns) do
    ~H"""
    <div>
      <div class="grid grid-cols-12 gap-4rem mb-4rem">
        <div class="col-span-7">
          <BusStopInfo busStopName={{@prop.bus_stop_name}} busStopNo={{@prop.bus_stop_no}} />
        </div>
        <div class="col-span-5">
        <DateTimeHorizontal day={{@prop.date_time.day}} date={{@prop.date_time.date}} time={{@prop.date_time.time}}/>
        </div>
      </div>
      <PredictionsTwoColumn realtimeActiveIndex={{@prop.predictions_realtime_set_2_column_index}} scheduledActiveIndex={{@prop.predictions_scheduled_set_2_column_index}} stopPredictionsRealtimeSet={{@prop.predictions_realtime_set_2_column}} stopPredictionsScheduledSet={{@prop.predictions_scheduled_set_2_column}} :if={{get_in(@prop.current_layout_panes, ["pane1", "type", "value"]) == "predictions_by_service"}}/>
      <AdvisoriesTwoColumn message={{@prop.message}} :if={{get_in(@prop.current_layout_panes, ["pane2", "type", "value"]) == "scheduled_and_ad_hoc_messages"}} />
    </div>
    """
  end
end
