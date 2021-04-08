defmodule AdvisoriesLandscape do
  @moduledoc false
  use Surface.LiveComponent

  alias DisplayWeb.DisplayLive.Utils

  property(message, :map, default: %{})
  property(panes, :map, default: %{})
  property(current_pane, :string, default: "pane2")

  def render(assigns) do
    ~H"""
    <div class="advisories-container m-top-component">
      <div class="floating-heading">Message Board</div>
      <div id={{get_in(@message, [:text])}} style={{Utils.advisories_animation_duration(@message)}} class={{Utils.get_message_class_names(@panes, @current_pane, @message)}}>
        <span>{{get_in(@message, [:text])}}</span>
      </div>
    </div>
    """
  end
end
