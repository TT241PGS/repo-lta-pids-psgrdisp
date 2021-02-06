defmodule QuickestWayToPortrait do
  @moduledoc false
  use Surface.LiveComponent

  property services, :string, default: ""

  def render(assigns) do
    ~H"""
    <div class="quickest-way">
      <div class="floating-heading">quickest way to</div>
      <div class="row">
        <div class={{"row-odd": index in [0,1], "row-even": index in [2,3]}} :for={{ {service, index} <- Enum.with_index(@services) }}>
          <div class="group-info">
            <div class="left-info">
              <p>{{get_in(service, ["poi","poi_name"])}}</p>
              <div class="tags">
                <div class="poi-wrapper" :if={{is_list(get_in(service, ["poi", "pictograms"]))}}>
                  <img :for={{ poi <- get_in(service, ["poi", "pictograms"]) }} class="tag" src="{{poi}}" alt="">
                </div>
              </div>
              <div class="floating-arrow"><i class="fas fa-arrow-right"></i></div>
            </div>
            <div class="right-info bus">
              <span class="number">{{service["service_no"]}}</span>
              <span class="status">{{service["arriving_time_at_origin"]}}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
