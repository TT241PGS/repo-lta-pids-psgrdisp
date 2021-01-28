defmodule AdvisoriesLandscape do
  @moduledoc false
  use Surface.LiveComponent

  alias DisplayWeb.DisplayLive.Utils

  property message, :map, default: %{}
  property panes, :map, default: %{}
  property current_pane, :string, default: "pane2"

  def render(assigns) do
    ~H"""
    <div class="advisories-container m-top-component">
      <div class="heading-wrapper">
        <div class="heading">
          <h1 :if={{get_in(@message, [:type]) == "MRT"}}>MRT Status</h1>
          <h1 :if={{get_in(@message, [:type]) != "MRT"}}>Advisories</h1>
        </div>
        <div class="tags" :if={{is_bitstring(get_in(@message, [:line]))}}>
          <img class="tag" src="{{get_in(@message, [:line])}}" alt="">
        </div>
      </div>
      <div class={{Utils.get_message_class_names(@panes, @current_pane, @message)}}>
        {{get_in(@message, [:text])}}
      </div>
    </div>
    """
  end
end
