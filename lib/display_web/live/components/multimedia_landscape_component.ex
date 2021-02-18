defmodule MultimediaLandscape do
  @moduledoc false
  use Surface.LiveComponent

  property multimedia, :map, default: %{type: nil, content: nil}
  property image_sequence_url, :string, default: nil
  property onePane, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div class={{"container", "two-columns", "multimedia" , "one-pane": @onePane == true}}>
      <img  width="67%" :if={{@multimedia.type == "IMAGE"}} class="thick-borders" src="{{@multimedia.content}}" style="margin: 50px auto; display: block" alt="">
      <video width="90%" :if={{@multimedia.type == "VIDEO"}} class="thick-borders" style="margin: 40px auto; display: block" autoplay loop>
        <source src="{{@multimedia.content}}" type="video/mp4" />
      </video>
      <img  width="67%" :if={{@multimedia.type == "IMAGE SEQUENCE"}} class="thick-borders" src="{{@image_sequence_url}}" style="margin: 50px auto; display: block" alt="">
    </div>
    """
  end
end
