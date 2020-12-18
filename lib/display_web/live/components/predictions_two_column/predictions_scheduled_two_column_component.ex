defmodule PredictionsScheduledTwoColumn do
  @moduledoc false
  use Surface.LiveComponent

  property stopPredictionsSet, :list, default: %{}
  property activeIndex, :integer, default: 0
  property suppressed_messages, :map, default: %{}

  def render(assigns) do
    ~H"""
    <div :for={{ {stopPredictionsColumns, index} <- Enum.with_index(@stopPredictionsSet) }} class={{"container", "two-columns", hidden: @activeIndex != index, "slide-in": @activeIndex == index}}>
      <div :for={{ {stopPredictionsColumn, columnIndex} <- Enum.with_index(stopPredictionsColumns) }} class={{"column", "left-column": columnIndex == 0, "right-column": columnIndex == 1}}>
        <div class="heading">
          <div class="two-columns-no-sidebar">
            <span class="heading-info bus">Bus</span>
            <span class="heading-info arriving">ARRIVING</span>
            <span class="heading-info next">Next</span>
          </div>
        </div>
        <div class={{"flex", "mb-30": service_index < 5}} :for={{ {service, service_index} <- Enum.with_index(stopPredictionsColumn) }}>
          <div class="sc-bdnylx dciVXD bus-info">{{service["ServiceNo"]}}</div>
          <div class="bus-info-message" :if={{get_in(@suppressed_messages, [:few_services, service["ServiceNo"]]) == nil and service["Status"] == "not_operating_today"}}>Service does not operate today.</div>
          <div class="bus-info-message" :if={{get_in(@suppressed_messages, [:few_services, service["ServiceNo"]]) == nil and service["Status"] == "last_trip_departed"}}>Last trip for the day has departed.</div>
          <div class="bus-info-message" :if={{get_in(@suppressed_messages, [:few_services, service["ServiceNo"]]) != nil}}>{{get_in(@suppressed_messages, [:few_services, service["ServiceNo"]])}}</div>
          <div class="next-buses" :if={{get_in(@suppressed_messages, [:few_services, service["ServiceNo"]]) == nil and service["Status"] == "operating_now"}}>
            <div class="next-buses-heading-info">
              <span class="stops">{{service["NoOfStops"]}}<i class="ml-1rem fas fa-arrow-right"></i></span>
              <p>{{service["DestinationCode"]}}</p>
            </div>
            <div class="details">
              <div class="next-bus" :for={{ next_bus <- service["NextBuses"] }}>
                <span class="indicator bg-charcoal"></span>
                <span class="label mb-0 font-bold">{{next_bus["EstimatedArrival"]}}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
