defmodule PredictionsScheduledTwoColumn do
  @moduledoc false
  use Surface.LiveComponent

  property stopPredictionsSet, :list, default: %{}

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
      <div class="bus-stop-predictions hidden">
        <div :for={{ stopPredictions <- @stopPredictionsSet }}>
          <div class="grid grid-rows-5 grid-flow-col gap-4rem mb-4rem">
            <div class={{"flex", "w-1/2": length(stopPredictions) <= 5}} :for={{ prediction <- stopPredictions }}>
              <div class="bus-info">{{prediction["ServiceNo"]}}</div>
              <div class="bus-info-message" :if={{prediction["Status"] == "not_operating_today"}}>Service does not operate today.</div>
              <div class="bus-info-message" :if={{prediction["Status"] == "last_trip_departed"}}>Last trip for the day has departed.</div>
              <div class="next-buses" :if={{prediction["Status"] == "operating_now"}}>
                <div class="heading">
                  <span class="stops" style="display: none"> no of stops # <i class="ml-1rem fas fa-arrow-right"></i></span>
                  <span class="stops">dest #</span>
                </div>
                <div class="details">
                  <div :for={{ next_bus <- prediction["NextBuses"] }}  class={{"next-bus mr-4rem no-icon justify-center", big: next_bus["Order"] == 1, small: next_bus["Order"] > 1 }}>
                    <span class="indicator bg-charcoal"></span>
                    <span class="label mb-0 font-bold">{{next_bus["EstimatedArrival"]}}</span>
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
