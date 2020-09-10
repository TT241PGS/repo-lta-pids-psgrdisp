defmodule PredictionsTwoColumn do
  use Surface.LiveComponent

  property stopPredictions, :list, default: %{}

  def render(assigns) do
    ~H"""
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
    <div class="grid grid-rows-5 grid-flow-col gap-4rem mb-4rem">
      <div class="flex" :for={{ service <- @stopPredictions }}>
        <div class="bus-info">{{service["ServiceNo"]}}</div>
        <div class="next-buses">
          <div class="heading">
            <span class="stops"> no of stops # <i class="ml-1rem fas fa-arrow-right"></i></span>
          </div>
          <div class="details">
            <div :if={{ Access.get(service, next_bus) != nil }} :for={{ next_bus <- ["NextBus", "NextBus2", "NextBus3"] }}  class={{"next-bus", "mr-4rem": next_bus != "NextBus3", "big": next_bus == "NextBus", "small": next_bus == "NextBus2" or next_bus == "NextBus3"}}>
              <span class={{"indicator", "bg-red": service["NextBus"]["Load"] == "LSD", "bg-yellow-1": service["NextBus"]["Load"] == "SDA", "bg-green-1": service["NextBus"]["Load"] == "SEA"}}></span>
              <span class="label">{{service[next_bus]["EstimatedArrival"]}}</span>
              <span>
                <img src="/images/bus_no_wab.svg" :if={{ service[next_bus]["Feature"] == "" }}>
                <img src="/images/bus_sd.svg" :if={{ service[next_bus]["Type"] == "SD" }}>
                <img src="/images/bus_dd.svg" :if={{ service[next_bus]["Type"] == "DD" }}>
                <img src="/images/bus_bd.svg" :if={{ service[next_bus]["Type"] == "BD" }}>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
