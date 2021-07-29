defmodule AdvisoriesPortrait do
  @moduledoc false
  use Surface.LiveComponent

  alias DisplayWeb.DisplayLive.Utils

  property(message, :map, default: %{})
  property(panes, :map, default: %{})
  property(current_pane, :string, default: "pane2")

  def render(assigns) do
    ~H"""
    <div class="advisories-container">
      <div class="floating-heading">Message Board</div>
      <div id={{get_in(@message, [:text])}} style={{Utils.get_message_style(@panes, @current_pane, @message)}} class={{Utils.get_message_class_names(@panes, @current_pane, @message)}}>
        <span><img src={{get_in(@message, [:line])}} > {{get_in(@message, [:text])}}</span>
      </div>
    </div>
    """
  end
end
