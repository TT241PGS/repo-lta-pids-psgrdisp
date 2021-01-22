defmodule AdvisoriesTwoColumn do
  @moduledoc false
  use Surface.LiveComponent

  property message, :map, default: %{}

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
      <div class="advisory-content">{{get_in(@message, [:text])}}</div>
    </div>
    """
  end
end
