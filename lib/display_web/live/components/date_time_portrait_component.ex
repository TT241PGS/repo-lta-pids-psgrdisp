defmodule DateTimePortrait do
  @moduledoc false
  use Surface.LiveComponent

  property day, :string, default: ""
  property date_short, :string, default: ""
  property time, :string, default: ""

  def render(assigns) do
    ~H"""
    <div class="portrait-clock">
      <div class="time"> {{@time}}</div>
      <div class="flex items-center justify-between">
        <div class="day">{{@day}}</div>
        <div class="date"> {{@date_short}}</div>
      </div>
    </div>
    """
  end
end
