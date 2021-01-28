defmodule LandscapeThreePaneALayout do
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
      <MultimediaLandscape multimedia={{@prop.multimedia}} image_sequence_url={{@prop.multimedia_image_sequence_current_url}} :if={{get_in(@prop.current_layout_panes, ["pane1", "type", "value"]) == "multimedia"}}/>
      <PredictionsTwoColumn suppressed_messages={{@prop.suppressed_messages}} realtimeActiveIndex={{@prop.predictions_realtime_set_2_column_index}} scheduledActiveIndex={{@prop.predictions_scheduled_set_2_column_index}} stopPredictionsRealtimeSet={{@prop.predictions_realtime_set_2_column}} stopPredictionsScheduledSet={{@prop.predictions_scheduled_set_2_column}} :if={{get_in(@prop.current_layout_panes, ["pane1", "type", "value"]) == "predictions_by_service"}}/>
      <QuickestWayToLandscape services={{@prop.quickest_way_to}} :if={{get_in(@prop.current_layout_panes, ["pane2", "type", "value"]) == "quickest_way_to" or get_in(@prop.current_layout_panes, ["pane3", "type", "value"]) == "quickest_way_to" and length(@prop.quickest_way_to) > 0}} />
      <AdvisoriesLandscape
        message={{@prop.message}}
        :if={{
          (get_in(@prop.current_layout_panes, ["pane2", "type", "value"]) == "scheduled_and_ad_hoc_messages" or
          get_in(@prop.current_layout_panes, ["pane3", "type", "value"]) == "scheduled_and_ad_hoc_messages") and
          @prop.message != %{}
        }}
        current_pane={{if get_in(@prop.current_layout_panes, ["pane2", "type", "value"]) == "scheduled_and_ad_hoc_messages", do: "pane2", else: "pane3"}}
        panes={{@prop.current_layout_panes}}
      />
      <IncomingBusLandscape incoming_buses={{@prop.incoming_buses}} :if={{get_in(@prop.current_layout_panes, ["pane2", "type", "value"]) == "next_buses_arriving_at_stop" or get_in(@prop.current_layout_panes, ["pane3", "type", "value"]) == "next_buses_arriving_at_stop" and length(@prop.incoming_buses) > 0}} />
    </div>
    """
  end
end
