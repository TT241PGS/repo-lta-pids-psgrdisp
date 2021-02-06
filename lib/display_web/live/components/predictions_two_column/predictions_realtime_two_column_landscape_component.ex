defmodule PredictionsRealtimeTwoColumnLandscape do
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
        <div class={{"flex", "mb-30": service_index < 5, hidden: Enum.member?(@suppressed_messages.hide_services, service["ServiceNo"])}} :for={{ {service, service_index} <- Enum.with_index(stopPredictionsColumn) }}>
          <div class="sc-bdnylx dciVXD bus-info">
            {{service["ServiceNo"]}}
            <span :if={{not is_nil(service["NextBus"]["BerthLabel"])}} style="font-size: 40px; font-weight: bold;">{{service["NextBus"]["BerthLabel"]}}</span>
          </div>
          <div class="bus-info-message" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) != nil}}>{{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]])}}</div>
          <div class="next-buses" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) == nil}}>
            <div class="next-buses-heading-info">
              <p>{{service["NextBus"]["Destination"]}}</p>
              <div class="poi-wrapper" :if={{is_list(service["NextBus"]["DestinationPictograms"])}}>
                <img :for={{ poi <- service["NextBus"]["DestinationPictograms"] }} src="{{poi}}" alt="">
              </div>
            </div>
            <div class="details">
              <div class="next-bus" :if={{ Access.get(service, next_bus) != nil }} :for={{ next_bus <- ["NextBus", "NextBus2", "NextBus3"] }}>
                <span class={{"indicator", "bg-yellow-1": service[next_bus]["Load"] in ["LSD", "SDA"], "bg-green-1": service[next_bus]["Load"] == "SEA"}}></span>
                <span class="label">{{service[next_bus]["EstimatedArrival"]}}</span>
                <span class="badge" :if={{is_nil(service["NextBus2"]) and is_nil(service["NextBus3"])}}>Last Bus</span>
                <span class="flex">
                  <img class="bus-feature-icon" src="/images/bus_no_wab.svg" :if={{ service[next_bus]["Feature"] == "" }}>
                  <img class="bus-feature-icon" src="/images/bus_sd.svg" :if={{ service[next_bus]["Type"] == "SD" }}>
                  <img class="bus-feature-icon" src="/images/bus_dd.svg" :if={{ service[next_bus]["Type"] == "DD" }}>
                  <img class="bus-feature-icon" src="/images/bus_bd.svg" :if={{ service[next_bus]["Type"] == "BD" }}>
                </span>
              </div>
            </div>
            <p :if={{not is_nil(service["NextBus"]["WayPoints"])}} style="color: white; font-size: 40px; padding-left: 20px">Via: {{service["NextBus"]["WayPoints"]}}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
