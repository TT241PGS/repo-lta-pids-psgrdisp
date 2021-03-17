defmodule LandscapeFourPaneBLayout do
  @moduledoc false
  use Surface.LiveComponent

  property prop, :map, default: %{}

  def render(assigns) do
    ~H"""
    <div>
      <header class="busStopInfo-time">
        <BusStopInfo busStopName={{@prop.bus_stop_name}} busStopNo={{@prop.bus_stop_no}} />
        <DateTimeHorizontal day={{@prop.date_time.day}} date={{@prop.date_time.date}} time={{@prop.date_time.time}}/>
      </header>
      <div class="container two-columns">
        <div class="column left-column">
          <div >
            <IncomingBusLandscape incoming_buses={{@prop.incoming_buses}} :if={{length(@prop.incoming_buses) > 0}} />
            <QuickestWayToLandscape maxLength=1 services={{@prop.quickest_way_to}} :if={{length(@prop.quickest_way_to) > 0}} />
            <MultimediaLandscape multimedia={{@prop.multimedia}} image_sequence_url={{@prop.multimedia_image_sequence_current_url}} :if={{get_in(@prop.current_layout_panes, ["pane3", "type", "value"]) == "multimedia"}}/>
          </div>
        </div>
        <div class="column right-column">
          <PredictionsLandscape is_bushub={{@prop.is_bushub}} suppressed_messages={{@prop.suppressed_messages}} realtimeActiveIndex={{@prop.predictions_realtime_7_per_page_index}} scheduledActiveIndex={{@prop.predictions_scheduled_7_per_page_index}} stopPredictionsRealtimeSet={{@prop.predictions_realtime_7_per_page}} stopPredictionsScheduledSet={{@prop.predictions_scheduled_7_per_page}} :if={{get_in(@prop.current_layout_panes, ["pane4", "type", "value"]) == "predictions_by_service"}}/>
        </div>
      </div>

    </div>
    """

    # <MultimediaLandscape multimedia={{@prop.multimedia}} image_sequence_url={{@prop.multimedia_image_sequence_current_url}} :if={{get_in(@prop.current_layout_panes, ["pane1", "type", "value"]) == "multimedia"}}/>
    # <IncomingBusLandscape incoming_buses={{@prop.incoming_buses}} :if={{get_in(@prop.current_layout_panes, ["pane1", "type", "value"]) == "next_buses_arriving_at_stop" or get_in(@prop.current_layout_panes, ["pane2", "type", "value"]) == "next_buses_arriving_at_stop" and length(@prop.incoming_buses) > 0}} />
    # <QuickestWayToLandscape services={{@prop.quickest_way_to}} :if={{get_in(@prop.current_layout_panes, ["pane2", "type", "value"]) == "quickest_way_to" or get_in(@prop.current_layout_panes, ["pane3", "type", "value"]) == "quickest_way_to" and length(@prop.quickest_way_to) > 0}} />
  end
end
