defmodule MultimediaPortrait do
  @moduledoc false
  use Surface.LiveComponent
  alias DisplayWeb.DisplayLive.Utils

  property multimedia, :map, default: %{type: nil, content: nil}
  property image_sequence_url, :string, default: nil
  property onePane, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div class={{Utils.one_pane_multimedia(@onePane)}} >
      <img :if={{@multimedia.type == "IMAGE"}} src="{{@multimedia.content}}" alt="">
      <video width="100%" :if={{@multimedia.type == "VIDEO"}} autoplay loop>
        <source src="{{@multimedia.content}}" type="video/mp4" />
      </video>
      <img :if={{@multimedia.type == "IMAGE SEQUENCE"}} src="{{@image_sequence_url}}" alt="">
    </div>
    """
  end
end
