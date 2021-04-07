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
      <style>
        @keyframes ticker {
          0% {
            margin-left: 100%;
          }
          100% {
              margin-left: {{Utils.advisories_animation_end_margin(@message)}};
          }
        }
      </style>
      <div class="heading-wrapper">
        <div class="heading">
          <svg :if={{get_in(@message, [:type]) == "MRT"}} width="38.077" height="45" viewBox="0 0 38.077 45">
            <path id="Icon_ionic-md-train" data-name="Icon ionic-md-train" d="M24.663,3.375c-9.519,0-19.038,1.179-19.038,9.476v22.5a8.31,8.31,0,0,0,8.329,8.286l-3.57,3.548v1.19H15.7l4.76-4.738h8.968l4.76,4.738h4.76V47.2l-3.57-3.548A8.317,8.317,0,0,0,43.7,35.362v-22.5C43.7,4.554,35.178,3.375,24.663,3.375ZM13.954,38.9a3.548,3.548,0,1,1,3.57-3.548A3.555,3.555,0,0,1,13.954,38.9Zm8.329-16.572h-11.9V12.851h11.9Zm4.76,0V12.851h11.9v9.476ZM35.373,38.9a3.548,3.548,0,1,1,3.57-3.548A3.555,3.555,0,0,1,35.373,38.9Z" transform="translate(-5.625 -3.375)" fill="#fff"/>
          </svg>
          <h1 :if={{get_in(@message, [:type]) == "MRT"}}>MRT Status</h1>
          <h1 :if={{get_in(@message, [:type]) != "MRT"}}>Advisories</h1>
        </div>
        <div class="tags" :if={{is_bitstring(get_in(@message, [:line]))}}>
          <img class="tag" src="{{get_in(@message, [:line])}}" alt="">
        </div>
      </div>
      <div id={{get_in(@message, [:text])}} style={{Utils.advisories_animation_duration(@message)}} class={{Utils.get_message_class_names(@panes, @current_pane, @message)}}>
        {{get_in(@message, [:text])}}
      </div>
    </div>
    """
  end
end
