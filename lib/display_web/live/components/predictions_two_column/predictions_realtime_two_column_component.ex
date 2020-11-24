defmodule PredictionsRealtimeTwoColumn do
  @moduledoc false
  use Surface.LiveComponent

  property stopPredictionsSet, :list, default: %{}
  property activeIndex, :integer, default: 0

  def render(assigns) do
    ~H"""
    <div>
      <div class="grid grid-cols-2 gap-4rem mb-4rem">
        <div class="flex w-full" :for={{ _ <- [1,2] }}>
          <div class="w-1/4">
            <span class="font-medium text-white uppercase bg-charcoal px-2rem py-1rem rounded-l-25 rounded-tr-25 text-3rem">Bus</span>
          </div>
          <div class="flex w-full ml-3rem">
            <div class="w-1/2">
              <span class="font-medium text-white uppercase bg-charcoal px-2rem py-1rem rounded-l-25 rounded-tr-25 text-3rem">ARRIVING</span>
            </div>
            <div class="w-1/2">
              <span class="font-medium text-white uppercase bg-charcoal px-2rem py-1rem rounded-l-25 rounded-tr-25 text-3rem">Next</span>
            </div>
          </div>
        </div>
      </div>
      <div class="bus-stop-predictions">
      <div :for={{ {stopPredictions, index} <- Enum.with_index(@stopPredictionsSet) }} class={{hidden: @activeIndex != index, "slide-in": @activeIndex == index}}>
          <div class="grid grid-rows-5 grid-flow-col gap-4rem mb-4rem">
            <div class={{"flex", "w-1/2": length(stopPredictions) <= 5}} :for={{ service <- stopPredictions }}>
              <div class="bus-info">{{service["ServiceNo"]}}</div>
              <div class="next-buses">
                <div class="heading">
                  <span class="stops" style="display: none"> no of stops # <i class="ml-1rem fas fa-arrow-right"></i></span>
                  <span class="stops">{{service["NextBus"]["DestinationCode"]}}</span>
                </div>
                <div class="details">
                  <div :if={{ Access.get(service, next_bus) != nil }} :for={{ next_bus <- ["NextBus", "NextBus2", "NextBus3"] }}  class={{"next-bus", "mr-4rem": next_bus != "NextBus3", big: next_bus == "NextBus", small: next_bus == "NextBus2" or next_bus == "NextBus3"}}>
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
      </div>
    </div>
    """
  end
end
