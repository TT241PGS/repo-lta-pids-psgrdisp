defmodule QuickestWayToPortrait do
  @moduledoc false
  use Surface.LiveComponent

  property(qwts, :string, default: "")

  def render(assigns) do
    ~H"""
    <div class="quickest-way">
      <div class="floating-heading">quickest way to</div>
      <div class="heading-2">Option 1</div>
      <div class="heading-3">Option 1</div>
      <div class="row">
        <div class={{"row", "row-odd": index in [0,2], "row-even": index in [1,3]}} :for={{ {qwt, index} <- Enum.with_index(@qwts) |> Enum.take(2) }}>
          <div class="group-info">
            <div class="left-info">
              <p>{{get_in(qwt, ["poi","poi_name"])}}</p>
              <div class="tags">
                <div class="poi-wrapper" :if={{is_list(get_in(qwt, ["poi", "pictograms"]))}}>
                  <img :for={{ poi <- get_in(qwt, ["poi", "pictograms"]) }} class="tag" src="{{poi}}" alt="">
                </div>
              </div>
            </div>
            <div class="flex items-center justify-between">
              <div :if={{get_in(qwt, ["type"]) == "alternate"}} class={{"right-info", "bus", "alternate"}}>
                <div class="floating-arrow"><i class="fas fa-arrow-right"></i></div>
                <span class="text">{{qwt["poi"]["poi_message"]}}</span>
              </div>
              <div :if={{get_in(qwt, ["type"]) != "alternate"}} class={{"right-info", "bus", "main"}} :for={{ {service, index} <- qwt["services"] |> Enum.with_index() }}>
                <div class="floating-arrow" :if={{index == 0}}><i class="fas fa-arrow-right"></i></div>
                <span class="number">{{service["service_no"]}}</span>
                <span class="status">{{service["arriving_time_at_origin"] |> String.replace_suffix(" min", " m")}}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
