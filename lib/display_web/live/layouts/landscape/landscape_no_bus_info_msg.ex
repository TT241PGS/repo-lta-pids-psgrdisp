defmodule LandscapeNoBusInfoMessage do
  @moduledoc false
  use Surface.LiveComponent

  alias DisplayWeb.DisplayLive.Utils

  property(prop, :map, default: %{})
  property(suppressed_msg, :string, default: nil)

  def render(assigns) do
    ~H"""
      <header class="busStopInfo-time">
        <BusStopInfo busStopName={{@prop.bus_stop_name}} busStopNo={{@prop.bus_stop_no |> Utils.pad_bus_stop_no}} />
        <DateTimeHorizontal day={{@prop.date_time.day}} date={{@prop.date_time.date}} time={{@prop.date_time.time}}/>
      </header>

      <div class="landscape-msg">
        <p :if={{ is_nil(@suppressed_msg) }}>
          Bus Arrival information is not currently available from this panel.
        </p>
        <p :if={{ is_nil(@suppressed_msg) }}>
          Please refer to poster at the shelter for information on bus services.
        </p>
        <p :if={{ not is_nil(@suppressed_msg) }}>
          {{@suppressed_msg}}
        </p>
      </div>
    """
  end
end
