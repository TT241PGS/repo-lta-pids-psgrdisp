defmodule PredictionsScheduledPortrait do
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
          <div class="bus-info-message" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) == nil and service["Status"] == "not_operating_today"}}>Service does not operate today.</div>
          <div class="bus-info-message" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) == nil and service["Status"] == "last_trip_departed"}}>{{service["DestinationCode"]}}<br>Last trip for the day has departed.</div>
          <div class="bus-info-message" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) != nil}}>{{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]])}}</div>
          <div class="next-buses flex" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) == nil and service["Status"] == "operating_now"}}>
            <div class="next-bus" :if={{ index < 2 }} :for={{ {next_bus, index} <- Enum.with_index(service["NextBuses"]) }}>
              <span class="label">{{next_bus["EstimatedArrival"]}}</span>
            </div>
            <div class="destination-bus-stop">
              <p>{{service["DestinationCode"]}}</p>
              <div class="next-bus-station-with-tags">
                <div class="tags">
                  <div class="poi-wrapper" :if={{is_list(service["DestinationPictograms"])}} :for={{ poi <- service["DestinationPictograms"] }}>
                    <img src="{{poi}}" alt="">
                  </div>
                </div>
                <div :if={{not is_nil(service["WayPoints"])}} class="text">{{service["WayPoints"]}}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
