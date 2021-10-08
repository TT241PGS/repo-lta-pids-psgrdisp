defmodule IncomingBusLandscape do
  @moduledoc false
  use Surface.LiveComponent

  property incoming_buses, :list, default: %{}

  def render(assigns) do
    ~H"""
    <div class="flex incoming-buses">
      <div class="incoming-bus-card">incoming buses</div>
      <div class="incoming-bus-conditions">*Buses might not arrive in exact order.</div>
      <div class="bus-card inverted no-bottom-border arriving" :for={{ bus <- @incoming_buses }}>
        <span class="base-number">{{bus["service_no"]}}</span>
        <span class="status">{{bus["time"]}}</span>
      </div>
    </div>
    """
  end
end
