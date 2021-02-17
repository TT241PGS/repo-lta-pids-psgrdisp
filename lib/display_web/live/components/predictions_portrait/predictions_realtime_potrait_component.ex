defmodule PredictionsRealtimePortrait do
  @moduledoc false
  use Surface.LiveComponent

  property stopPredictionsSet, :list, default: %{}
  property activeIndex, :integer, default: 0
  property suppressed_messages, :map, default: %{}

  def render(assigns) do
    ~H"""
    <div class="heading">
      <span class="heading-info service">Services</span>
      <span class="heading-info arriving">ARRIVING</span>
      <span class="heading-info nextBus">Next Bus</span>
      <span class="heading-info destination">Destination</span>
    </div>
    <div :for={{ {stopPredictionsPage, index} <- Enum.with_index(@stopPredictionsSet) }} class={{"container", hidden: @activeIndex != index, "slide-in": @activeIndex == index}}>
      <div>
        <div class={{"flex", "mb-30", "row-odd": rem(service_index, 2) != 0, "row-even": rem(service_index, 2) == 0, hidden: Enum.member?(@suppressed_messages.hide_services, service["ServiceNo"])}} :for={{ {service, service_index} <- Enum.with_index(stopPredictionsPage) }}>
          <div class="sc-bdnylx dciVXD bus-info">
            {{service["ServiceNo"]}}
            <span :if={{not is_nil(service["NextBus"]["BerthLabel"])}} style="font-size: 40px; font-weight: bold;">{{service["NextBus"]["BerthLabel"]}}</span>
          </div>
          <div class="bus-info-message" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) != nil}}>{{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]])}}</div>
          <div class="next-buses flex" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) == nil}}>
            <div class="next-bus" :if={{ Access.get(service, next_bus) != nil }} :for={{ next_bus <- ["NextBus", "NextBus2"] }}>
              <span class={{"indicator", "bg-yellow-1": service[next_bus]["Load"] in ["LSD", "SDA"], "bg-green-1": service[next_bus]["Load"] == "SEA"}}></span>
              <span class="badge" :if={{is_nil(service["NextBus2"]) and is_nil(service["NextBus3"])}}>Last Bus</span>
              <span class="label">{{service[next_bus]["EstimatedArrival"]}}</span>
              <span class="flex">
                <img class="bus-feature-icon" src="/images/bus_no_wab.svg" :if={{ service[next_bus]["Feature"] == "" }}>
                <img class="bus-feature-icon" src="/images/bus_sd.svg" :if={{ service[next_bus]["Type"] == "SD" }}>
                <img class="bus-feature-icon" src="/images/bus_dd.svg" :if={{ service[next_bus]["Type"] == "DD" }}>
                <img class="bus-feature-icon" src="/images/bus_bd.svg" :if={{ service[next_bus]["Type"] == "BD" }}>
              </span>
            </div>
            <div class="destination-bus-stop">
              <p>{{service["NextBus"]["Destination"]}}</p>
              <div class="next-bus-station-with-tags">
                <div class="tags">
                  <div class="poi-wrapper" :if={{is_list(service["NextBus"]["DestinationPictograms"])}}>
                    <img :for={{ poi <- service["NextBus"]["DestinationPictograms"] }} src="{{poi}}" alt="">
                  </div>
                </div>
                <div :if={{not is_nil(service["NextBus"]["WayPoints"])}} class="text">{{service["NextBus"]["WayPoints"]}}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
