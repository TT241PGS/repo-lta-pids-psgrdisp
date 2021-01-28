defmodule PortraitThreePaneBLayout do
  @moduledoc false
  use Surface.LiveComponent

  alias DisplayWeb.DisplayLive.Utils

  property(prop, :map, default: %{})
  property(service_per_page, :string, default: "5")

  def render(assigns) do
    ~H"""
    <div>
      <BusStopInfo busStopName={{@prop.bus_stop_name}} busStopNo={{@prop.bus_stop_no}} />
      <DateTimeHorizontal day={{@prop.date_time.day}} date={{@prop.date_time.date}} time={{@prop.date_time.time}}/>
      <IncomingBusPortrait incoming_buses={{@prop.incoming_buses}} :if={{get_in(@prop.current_layout_panes, ["pane1", "type", "value"]) == "next_buses_arriving_at_stop" and length(@prop.incoming_buses) > 0}} />
      <PredictionsPortrait
        suppressed_messages={{@prop.suppressed_messages}}
        realtimeActiveIndex={{Utils.get_realtime_active_index(@prop, @service_per_page)}}
        scheduledActiveIndex={{Utils.get_scheduled_active_index(@prop, @service_per_page)}}
        stopPredictionsRealtimeSet={{Utils.get_stop_predictions_realtime_set(@prop, @service_per_page)}}
        stopPredictionsScheduledSet={{Utils.get_stop_predictions_scheduled_set(@prop, @service_per_page)}}
        :if={{get_in(@prop.current_layout_panes, ["pane2", "type", "value"]) == "predictions_by_service"}}
      />
      <MultimediaPortrait
        multimedia={{@prop.multimedia}}
        image_sequence_url={{@prop.multimedia_image_sequence_current_url}}
        :if={{get_in(@prop.current_layout_panes, ["pane3", "type", "value"]) == "multimedia"}}
      />
    </div>
    """
  end
end
