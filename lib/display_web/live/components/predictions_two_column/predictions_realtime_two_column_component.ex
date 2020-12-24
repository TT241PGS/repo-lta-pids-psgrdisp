defmodule PredictionsRealtimeTwoColumn do
  @moduledoc false
  use Surface.LiveComponent

  property stopPredictionsSet, :list, default: %{}
  property activeIndex, :integer, default: 0

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
          <div class="next-buses">
            <div class="next-buses-heading-info">
              <span class="stops">{{service["NoOfStops"]}}<i class="ml-1rem fas fa-arrow-right"></i></span>
              <p>{{service["NextBus"]["DestinationCode"]}}</p>
            </div>
            <div class="details">
              <div class="next-bus" :if={{ Access.get(service, next_bus) != nil }} :for={{ next_bus <- ["NextBus", "NextBus2", "NextBus3"] }}>
                <span class={{"indicator", "bg-red": service["NextBus"]["Load"] == "LSD", "bg-yellow-1": service["NextBus"]["Load"] == "SDA", "bg-green-1": service["NextBus"]["Load"] == "SEA"}}></span>
                <span class="label">{{service[next_bus]["EstimatedArrival"]}}</span>
                <span class="flex">
                  <img class="bus-feature-icon" src="/images/bus_no_wab.svg" :if={{ service[next_bus]["Feature"] == "" }}>
                  <img class="bus-feature-icon" src="/images/bus_sd.svg" :if={{ service[next_bus]["Type"] == "SD" }}>
                  <img class="bus-feature-icon" src="/images/bus_dd.svg" :if={{ service[next_bus]["Type"] == "DD" }}>
                  <img class="bus-feature-icon" src="/images/bus_bd.svg" :if={{ service[next_bus]["Type"] == "BD" }}>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
