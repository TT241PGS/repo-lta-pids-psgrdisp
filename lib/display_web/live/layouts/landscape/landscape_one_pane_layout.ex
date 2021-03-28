defmodule LandscapeOnePaneLayout do
  @moduledoc false
  use Surface.LiveComponent

  alias DisplayWeb.DisplayLive.Utils

  property prop, :map, default: %{}

  def render(assigns) do
    ~H"""
    <div>
      <header class="busStopInfo-time">
        <BusStopInfo busStopName={{@prop.bus_stop_name}} busStopNo={{@prop.bus_stop_no |> Utils.pad_bus_stop_no}} />
        <DateTimeHorizontal day={{@prop.date_time.day}} date={{@prop.date_time.date}} time={{@prop.date_time.time}}/>
      </header>
      <div class="container two-columns">
        <PredictionsLandscape is_bus_interchange={{@prop.is_bus_interchange}} suppressed_messages={{@prop.suppressed_messages}} realtimeActiveIndex={{@prop.predictions_realtime_14_per_page_index}} scheduledActiveIndex={{@prop.predictions_scheduled_14_per_page_index}} stopPredictionsRealtimeSet={{@prop.predictions_realtime_14_per_page}} stopPredictionsScheduledSet={{@prop.predictions_scheduled_14_per_page}} :if={{get_in(@prop.current_layout_panes, ["pane1", "type", "value"]) == "predictions_by_service"}} twoColumn=true/>
      </div>
      <MultimediaLandscape multimedia={{@prop.multimedia}} image_sequence_url={{@prop.multimedia_image_sequence_current_url}} onePane=true :if={{get_in(@prop.current_layout_panes, ["pane1", "type", "value"]) == "multimedia"}}/>
    </div>
    """
  end
end
