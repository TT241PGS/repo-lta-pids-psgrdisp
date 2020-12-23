defmodule IncomingBusTwoColumn do
  @moduledoc false
  use Surface.LiveComponent

  property incoming_buses, :list, default: %{}

  def render(assigns) do
    ~H"""
    <div class="flex incoming-buses">
      <div class="incoming-bus-card">incoming<br>bus</div>

      <div class="bus-card inverted no-bottom-border" :for={{ bus <- @incoming_buses }}>
        <span class="number">{{bus["service_no"]}}</span>
        <span class="status">{{bus["time"]}}</span>
      </div>
    </div>
    """
  end
end