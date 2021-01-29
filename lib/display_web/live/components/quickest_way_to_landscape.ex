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
            <div class="text">{{get_in(service, ["poi","poi_name"])}}</div>
            <div class="tags">
              <div class="poi-wrapper" :if={{is_list(get_in(service, ["poi", "pictograms"]))}} :for={{ poi <- get_in(service, ["poi", "pictograms"]) }}>
                <img class="tag" src="{{poi}}" alt="">
              </div>
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
