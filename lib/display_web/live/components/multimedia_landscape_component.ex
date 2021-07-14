defmodule MultimediaLandscape do
  @moduledoc false
  use Surface.LiveComponent

  property multimedia, :map, default: %{type: nil, content: nil}
  property image_sequence_url, :string, default: nil
  property onePane, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div class={{"container", "two-columns", "multimedia" , "one-pane": @onePane == true}}>
      <img :if={{@multimedia.type == "IMAGE"}} class="thick-borders media-item" src="{{@multimedia.content}}" alt="">
      <video :if={{@multimedia.type == "VIDEO"}} volume={{@panel_audio_lvl}} class="thick-borders media-item" autoplay loop>
        <source src="{{@multimedia.content}}" type="video/mp4" />
      </video>
      <img :if={{@multimedia.type == "IMAGE SEQUENCE"}} class="thick-borders media-item" src="{{@image_sequence_url}}" alt="">
    </div>
    """
  end
end
