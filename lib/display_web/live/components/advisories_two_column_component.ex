defmodule AdvisoriesTwoColumn do
  @moduledoc false
  use Surface.LiveComponent

  property message, :string, default: ""

  def render(assigns) do
    ~H"""
    <div class="advisories-container mb-4rem">
      <div class="flex flex-row items-center">
        <div class="heading">
          <svg width="38.077" height="45" viewBox="0 0 38.077 45">
            <path
              id="Icon_ionic-md-train"
              data-name="Icon ionic-md-train"
              d="M24.663,3.375c-9.519,0-19.038,1.179-19.038,9.476v22.5a8.31,8.31,0,0,0,8.329,8.286l-3.57,3.548v1.19H15.7l4.76-4.738h8.968l4.76,4.738h4.76V47.2l-3.57-3.548A8.317,8.317,0,0,0,43.7,35.362v-22.5C43.7,4.554,35.178,3.375,24.663,3.375ZM13.954,38.9a3.548,3.548,0,1,1,3.57-3.548A3.555,3.555,0,0,1,13.954,38.9Zm8.329-16.572h-11.9V12.851h11.9Zm4.76,0V12.851h11.9v9.476ZM35.373,38.9a3.548,3.548,0,1,1,3.57-3.548A3.555,3.555,0,0,1,35.373,38.9Z"
              transform="translate(-5.625 -3.375)"
              fill="#fff"
            ></path>
          </svg>
          <h1>Advisories</h1>
        </div>
      </div>
      <div class="advisory-content">
        <ul class="message-slides">
          <li class="message-slide" >{{@message}}</li>
        </ul>
      </div>
    </div>
    """
  end
end
