defmodule IncomingBusTwoColumn do
  @moduledoc false
  use Surface.LiveComponent

  property incoming_buses, :list, default: %{}

  def render(assigns) do
    ~H"""
    <div class="incoming-bus-container mb-4rem">
      <div class="flex">
        <div class="font-bold text-white uppercase border-white border-solid text-4rem border-t-3 border-l-3 border-r-3 rounded-t-35 mr-2rem px-2rem pt-2rem">
          incoming<br />
          bus
        </div>
        <div class="bus-card light no-bottom-border mr-2rem" :for={{ bus <- @incoming_buses }}>
          <span class="number">{{bus["service_no"]}}</span>
          <span class="status">{{bus["time"]}}</span>
        </div>
      </div>
    </div>
    """
  end
end
