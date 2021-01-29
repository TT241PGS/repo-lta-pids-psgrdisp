defmodule MultimediaPortrait do
  @moduledoc false
  use Surface.LiveComponent

  property multimedia, :map, default: %{type: nil, content: nil}
  property image_sequence_url, :string, default: nil

  def render(assigns) do
    ~H"""
    <div class="image-wrapper">
      <img :if={{@multimedia.type == "IMAGE"}} src="{{@multimedia.content}}" alt="">
      <video width="100%" :if={{@multimedia.type == "VIDEO"}} autoplay muted loop>
        <source src="{{@multimedia.content}}" type="video/mp4" />
      </video>
      <img :if={{@multimedia.type == "IMAGE SEQUENCE"}} src="{{@image_sequence_url}}" alt="">
    </div>
    """
  end
end
