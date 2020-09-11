defmodule BusStopInfo do
  @moduledoc false
  use Surface.LiveComponent

  property busStopNo, :string, default: ""
  property busStopName, :string, default: ""

  def render(assigns) do
    ~H"""
    <div class="bus-stop-info">
      <div class="bus-stop-number">{{ @busStopNo }}</div>
      <div class="bus-stop-name">{{ @busStopName }} </div>
    </div>
    """
  end
end
