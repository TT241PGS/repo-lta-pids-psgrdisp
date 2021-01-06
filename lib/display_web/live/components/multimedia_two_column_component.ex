defmodule MultimediaTwoColumn do
  @moduledoc false
  use Surface.LiveComponent

  property multimedia, :map, default: %{type: nil, content: nil}

  def render(assigns) do
    ~H"""
    <div class="container two-columns">
      <div class="column left-column">
        <div class="thick-borders">
          <div class="content" :if={{@multimedia.type == "IMAGE"}}>
            <img width="1805px" src="{{@multimedia.content}}" style="display: block" alt="">
          </div>
        </div>
      </div>
    </div>
    """
  end
end
