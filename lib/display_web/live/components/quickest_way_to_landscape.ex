defmodule QuickestWayToLandscape do
  @moduledoc false
  use Surface.LiveComponent

  property services, :string, default: ""

  def render(assigns) do
    ~H"""
    <div class="container two-columns">
      <div class={{"column", "left-column": service_index == 0, "right-column": service_index == 1}} :for={{ {service, service_index} <- Enum.with_index(@services) }}>
        <div class="flex justify-between heading"><span class="heading-info">DESTINATION</span><span
            class="heading-info">BUS</span></div>
        <div class="flex">
          <div class="destination-card-with-multiple-tags col-span-4">
            <div class="text">{{service["poi_name"]}}</div>
            <div class="tags hidden">
              <span class="tag bg-green-1">Ewl</span>
              <span class="tag bg-red">nsl</span>
            </div>
            <div class="floating-arrow right">
              <i class="fas fa-arrow-left"></i>
            </div>
          </div>
          <div class="bus-card">
            <span class="number">{{service["service_no"]}}</span>
            <span class="status">{{service["arriving_time_at_origin"]}}</span>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
