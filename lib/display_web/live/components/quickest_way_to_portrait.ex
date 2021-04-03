defmodule QuickestWayToPortrait do
  @moduledoc false
  use Surface.LiveComponent

  property(services, :string, default: "")

  def render(assigns) do
    ~H"""
    <div class="quickest-way">
      <div class="floating-heading">quickest way to</div>
      <div class="row">
        <div class={{"row", "row-odd": index in [0,2], "row-even": index in [1,3]}} :for={{ {service, index} <- Enum.with_index(@services) |> Enum.take(4) }}>
          <div class="group-info">
            <div class="left-info">
              <p>{{get_in(service, ["poi","poi_name"])}}</p>
              <div class="tags">
                <div class="poi-wrapper" :if={{is_list(get_in(service, ["poi", "pictograms"]))}}>
                  <img :for={{ poi <- get_in(service, ["poi", "pictograms"]) }} class="tag" src="{{poi}}" alt="">
                </div>
              </div>
            </div>
            <div class="flex items-center justify-between">
              <div class={{"right-info", "bus", alternate: get_in(service, ["type"]) == "alternate", main: get_in(service, ["type"]) == "main"}}>
                <div class="floating-arrow"><i class="fas fa-arrow-right"></i></div>
                <span :if={{get_in(service, ["type"]) == "main"}} class="number">{{service["service_no"]}}</span>
                <span :if={{get_in(service, ["type"]) == "main"}} class="status">{{service["arriving_time_at_origin"]}}</span>
                <span :if={{get_in(service, ["type"]) == "alternate"}} class="text">{{service["poi"]["poi_message"]}}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
