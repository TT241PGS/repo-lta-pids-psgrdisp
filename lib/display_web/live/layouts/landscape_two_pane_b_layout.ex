defmodule LandscapeTwoPaneBLayout do
  @moduledoc false
  use Surface.LiveComponent

  property(prop, :map, default: %{})

  def render(assigns) do
    ~H"""
    <div>
      <header class="busStopInfo-time">
        <BusStopInfo busStopName={{@prop.bus_stop_name}} busStopNo={{@prop.bus_stop_no}} />
        <DateTimeHorizontal day={{@prop.date_time.day}} date={{@prop.date_time.date}} time={{@prop.date_time.time}}/>
      </header>
      <PredictionsTwoColumn suppressed_messages={{@prop.suppressed_messages}} realtimeActiveIndex={{@prop.predictions_realtime_set_2_column_index}} scheduledActiveIndex={{@prop.predictions_scheduled_set_2_column_index}} stopPredictionsRealtimeSet={{@prop.predictions_realtime_set_2_column}} stopPredictionsScheduledSet={{@prop.predictions_scheduled_set_2_column}} :if={{get_in(@prop.current_layout_panes, ["pane1", "type", "value"]) == "predictions_by_service"}}/>
      <QuickestWayToTwoColumn services={{@prop.quickest_way_to}} :if={{get_in(@prop.current_layout_panes, ["pane2", "type", "value"]) == "quickest_way_to" and length(@prop.quickest_way_to) > 0}} />
      <AdvisoriesTwoColumn message={{@prop.message}} :if={{get_in(@prop.current_layout_panes, ["pane2", "type", "value"]) == "scheduled_and_ad_hoc_messages"}} />
    </div>
    """
  end
end
