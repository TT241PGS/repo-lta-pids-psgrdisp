defmodule DateTimeHorizontal do
  @moduledoc false
  use Surface.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="sc-dlnjPT hrYkFG clock-with-date-horizontal">
      <div class="date" id="day"></div>
      <div class="date with-border" id="date"></div>
      <div class="time with-border" id="time"></div>
    </div>
    """
  end
end
