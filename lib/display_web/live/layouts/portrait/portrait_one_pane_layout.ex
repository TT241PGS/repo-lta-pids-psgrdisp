defmodule PortraitOnePaneLayout do
  @moduledoc false
  use Surface.LiveComponent

  alias DisplayWeb.DisplayLive.Utils

  property(prop, :map, default: %{})
  property(service_per_page, :string, default: "11")

  def render(assigns) do
    ~H"""
    <div style="flex-direction: column; height: 100%; display: flex" :if={{Utils.get_stop_predictions_realtime_set(@prop, @service_per_page) |> is_list and length(Utils.get_stop_predictions_realtime_set(@prop, @service_per_page)) > 0 }}>
      <div class="flex items-center justify-between">
        <BusStopInfo busStopName={{@prop.bus_stop_name}} busStopNo={{@prop.bus_stop_no |> Utils.pad_bus_stop_no}} />
        <DateTimePortrait day={{@prop.date_time.day}} date_short={{@prop.date_time.date_short}} time={{@prop.date_time.time}}/>
      </div>

      <PredictionsPortrait
        is_bus_interchange={{@prop.is_bus_interchange}}
        suppressed_messages={{@prop.suppressed_messages}}
        realtimeActiveIndex={{Utils.get_realtime_active_index(@prop, @service_per_page)}}
        scheduledActiveIndex={{Utils.get_scheduled_active_index(@prop, @service_per_page)}}
        stopPredictionsRealtimeSet={{Utils.get_stop_predictions_realtime_set(@prop, @service_per_page)}}
        stopPredictionsScheduledSet={{Utils.get_stop_predictions_scheduled_set(@prop, @service_per_page)}}
        :if={{get_in(@prop.current_layout_panes, ["pane1", "type", "value"]) == "predictions_by_service"}}
      />
      <MultimediaPortrait
      onePane=true
      multimedia={{@prop.multimedia}}
      image_sequence_url={{@prop.multimedia_image_sequence_current_url}}
      :if={{get_in(@prop.current_layout_panes, ["pane1", "type", "value"]) == "multimedia"}}
    />
      <Legend
      :if={{get_in(@prop.current_layout_panes, ["pane1", "type", "value"]) == "predictions_by_service"}}
       />
    </div>
    """
  end
end
