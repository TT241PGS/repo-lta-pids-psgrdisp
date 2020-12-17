defmodule DateTimeHorizontal do
  @moduledoc false
  use Surface.LiveComponent

  property day, :string, default: ""
  property date, :string, default: ""
  property time, :string, default: ""

  def render(assigns) do
    ~H"""
    <div class="sc-dlnjPT hrYkFG clock-with-date-horizontal">
      <div class="day">{{@day}}</div>
      <div class="date with-border">{{@date}}</div>
      <div class="time with-border">{{@time}}</div>
    </div>
    """
  end
end
