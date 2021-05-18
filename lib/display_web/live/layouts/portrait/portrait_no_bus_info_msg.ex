defmodule PortraitNoBusInfoMessage do
  @moduledoc false
  use Surface.LiveComponent

  alias DisplayWeb.DisplayLive.Utils

  property(prop, :map, default: %{})

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-between">
      <BusStopInfo busStopName={{@prop.bus_stop_name}} busStopNo={{@prop.bus_stop_no |> Utils.pad_bus_stop_no}} />
      <DateTimePortrait day={{@prop.date_time.day}} date_short={{@prop.date_time.date_short}} time={{@prop.date_time.time}}/>
    </div>

    <div class="portrait-msg">
      <p>
        Bus Arrival information is not currently available from this panel.
      </p>
      <p>
        Please refer to poster at the shelter for information on bus services.
      </p>
    </div>
    """
  end
end
