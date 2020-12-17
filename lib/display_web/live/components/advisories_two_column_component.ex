defmodule AdvisoriesTwoColumn do
  @moduledoc false
  use Surface.LiveComponent

  property message, :string, default: ""

  def render(assigns) do
    ~H"""
    <div class="advisories-container">
      <div class="heading-wrapper">
        <div class="heading">
          <h1>Advisories</h1>
        </div>
      </div>
      <div class="advisory-content">{{@message}}</div>
    </div>
    """
  end
end
