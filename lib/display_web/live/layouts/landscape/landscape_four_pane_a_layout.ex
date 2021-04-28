defmodule LandscapeFourPaneALayout do
  @moduledoc false
  use Surface.LiveComponent

  alias DisplayWeb.DisplayLive.Utils

  property(prop, :map, default: %{})

  def render(assigns) do
    ~H"""
    <div :if={{is_list(@prop.predictions_realtime_6_per_page) and length(@prop.predictions_realtime_6_per_page) > 0}}>
      <header class="busStopInfo-time">
        <BusStopInfo busStopName={{@prop.bus_stop_name}} busStopNo={{@prop.bus_stop_no |> Utils.pad_bus_stop_no}} />
        <DateTimeHorizontal day={{@prop.date_time.day}} date={{@prop.date_time.date}} time={{@prop.date_time.time}}/>
      </header>
      <div class="container two-columns">
        <div class="column left-column">
          <div :for={{pane <- ["pane1", "pane2", "pane3"]}}>
            <div :if={{(Utils.get_content_type(@prop.current_layout_panes, pane) == "next_buses_arriving_at_stop")}}>
              <IncomingBusLandscape incoming_buses={{@prop.incoming_buses}} :if={{length(@prop.incoming_buses) > 0}} />
            </div>
            <div :if={{(Utils.get_content_type(@prop.current_layout_panes, pane) == "quickest_way_to")}}>
              <QuickestWayToLandscape maxLength=4 qwts={{@prop.quickest_way_to}} :if={{length(@prop.quickest_way_to) > 0}} />
            </div>

            <div :if={{(Utils.get_content_type(@prop.current_layout_panes, pane) == "scheduled_and_ad_hoc_messages")}}>
              <AdvisoriesLandscape
                message={{@prop.message}}
                :if={{
                  (Utils.get_content_type(@prop.current_layout_panes, pane) == "scheduled_and_ad_hoc_messages") and
                  @prop.message != %{}
                }}
                current_pane={{pane}}
                panes={{@prop.current_layout_panes}}
              />
            </div>
          </div>
        </div>
        <div class="column right-column">
          <PredictionsLandscape is_bus_interchange={{@prop.is_bus_interchange}} suppressed_messages={{@prop.suppressed_messages}} realtimeActiveIndex={{@prop.predictions_realtime_6_per_page_index}} scheduledActiveIndex={{@prop.predictions_scheduled_6_per_page_index}} stopPredictionsRealtimeSet={{@prop.predictions_realtime_6_per_page}} stopPredictionsScheduledSet={{@prop.predictions_scheduled_6_per_page}} :if={{get_in(@prop.current_layout_panes, ["pane4", "type", "value"]) == "predictions_by_service"}}/>
          <Legend />
        </div>
      </div>

    </div>
    """
  end
end
