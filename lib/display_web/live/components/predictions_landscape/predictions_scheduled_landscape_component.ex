defmodule PredictionsScheduledLandscape do
  @moduledoc false
  use Surface.LiveComponent

  property(stopPredictionsSet, :list, default: %{})
  property(activeIndex, :integer, default: 0)
  property(suppressed_messages, :map, default: %{})
  property(twoColumn, :boolean, default: false)

  def render(assigns) do
    ~H"""
    <div>
      <div class={{"heading", bushub: @is_bus_interchange == true}} :if={{@twoColumn == false}}>
        <div class="two-columns-no-sidebar">
          <span class="heading-info bus">BUS</span>
          <span class="heading-info arriving">ARRIVING(min)</span>
          <span class="heading-info next">NEXT(min)</span>
        </div>
      </div>
      <div class="container two-columns" :if={{@twoColumn == true}}>
        <div class="column left-column">
          <div class={{"heading", bushub: @is_bus_interchange == true}}>
            <span class="heading-info service">SERVICE</span>
            <span class="heading-info arriving">ARRIVING(min)</span>
            <span class="heading-info nextBus">NEXT BUS(min)</span>
            <span :if={{@is_bus_interchange == true}} class="heading-info berthHead">BERTH</span>
            <span class="heading-info destination">DESTINATION</span>
          </div>
        </div>
        <div class="column right-column">
          <div class={{"heading", bushub: @is_bus_interchange == true}}>
          <span class="heading-info service">SERVICE</span>
          <span class="heading-info arriving">ARRIVING(min)</span>
          <span class="heading-info nextBus">NEXT BUS(min)</span>
          <span :if={{@is_bus_interchange == true}} class="heading-info berthHead">BERTH</span>
          <span class="heading-info destination">DESTINATION</span>
        </div>
        </div>
      </div>
      <div :for={{ {stopPredictionsPage, index} <- Enum.with_index(@stopPredictionsSet) }} class={{"container", hidden: @activeIndex != index, "fade-in": @activeIndex == index}}>
        <div class={{"grid-row-7": @twoColumn == true}}>
          <div class={{"flex", "mb-30", "mr-30": @twoColumn == true, "row-odd": rem(service_index, 2) != 0, "row-even": rem(service_index, 2) == 0, hidden: Enum.member?(@suppressed_messages.hide_services, service["ServiceNo"]), bushub: @is_bus_interchange == true}} :for={{ {service, service_index} <- Enum.with_index(stopPredictionsPage) }}>
            <div class="sc-bdnylx dciVXD bus-info">
              {{service["ServiceNo"]}}
            </div>
            <div class="bus-info-message" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) == nil and service["Status"] == "not_operating_today"}}>Service does not operate today.</div>
            <div class="bus-info-message" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) == nil and service["Status"] == "last_trip_departed"}}>{{service["DestinationCode"]}}<br>Last trip for the day has departed.</div>
            <div class="bus-info-message" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) != nil}}>{{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]])}}</div>
            <div class="next-buses flex" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) == nil and service["Status"] == "operating_now"}}>
              <div class="next-bus scheduled" :if={{ index < 2 }} :for={{ {next_bus, index} <- Enum.with_index(service["NextBuses"]) }}>
                <span class="badge" :if={{next_bus["isLastBus"] == true}}>Last Bus</span>
                <span class="label">{{next_bus["EstimatedArrival"]}}</span>
              </div>
              <div class="next-bus scheduled no-more" :if={{ length(service["NextBuses"]) == 1 }}>
                <span class="label">No More Next Bus</span>
              </div>
              <div :if={{@is_bus_interchange == true}} class="berth">{{get_in(service, ["NextBus", "BerthLabel"])}}</div>
              <div class="destination-bus-stop">
                <p>{{service["DestinationCode"]}}</p>
                <div class="next-bus-station-with-tags">
                  <div class="tags">
                    <div class="poi-wrapper" :if={{is_list(service["DestinationPictograms"])}}>
                      <img :for={{ poi <- service["DestinationPictograms"] }} src="{{poi}}" alt="">
                    </div>
                  </div>
                  <div :if={{not is_nil(service["WayPoints"])}} class={{"text", ticker: String.length(service["NextBus"]["WayPoints"]) > 27}}>{{service["WayPoints"]}}</div>
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
