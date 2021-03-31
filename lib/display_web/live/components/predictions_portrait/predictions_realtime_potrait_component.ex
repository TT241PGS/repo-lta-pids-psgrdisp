defmodule PredictionsRealtimePortrait do
  @moduledoc false
  use Surface.LiveComponent

  alias DisplayWeb.DisplayLive.Utils

  property(stopPredictionsSet, :list, default: %{})
  property(activeIndex, :integer, default: 0)
  property(suppressed_messages, :map, default: %{})
  property(is_bus_interchange, :boolean, default: false)

  def render(assigns) do
    ~H"""
    <div class={{"heading", bushub: @is_bus_interchange == true}}>
      <span class="heading-info service">SERVICE</span>
      <span class="heading-info arriving">ARRIVING(min)</span>
      <span class="heading-info nextBus">NEXT BUS(min)</span>
      <span :if={{@is_bus_interchange == true}} class="heading-info berthHead">BERTH</span>
      <span class="heading-info destination">DESTINATION</span>
      <span class="page-count" :if={{length(@stopPredictionsSet) > 1}}>
        <b :if={{not is_nil(@activeIndex)}}>{{@activeIndex + 1}}</b>
        &nbsp;/&nbsp;{{length(@stopPredictionsSet)}}
      </span>
    </div>
    <div :for={{ {stopPredictionsPage, index} <- Enum.with_index(@stopPredictionsSet) }} class={{"container", hidden: @activeIndex != index, "fade-in": @activeIndex == index}}>
      <div>
        <div class={{"flex", "mb-30", "row-odd": rem(service_index, 2) != 0, "row-even": rem(service_index, 2) == 0, hidden: Enum.member?(@suppressed_messages.hide_services, service["ServiceNo"]), bushub: @is_bus_interchange == true}} :for={{ {service, service_index} <- Enum.with_index(stopPredictionsPage) }}>
          <div class="sc-bdnylx dciVXD bus-info">
            {{service["ServiceNo"]}}
          </div>
          <div class="bus-info-message" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) != nil}}>{{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]])}}</div>
          <div class="next-buses flex" :if={{get_in(@suppressed_messages, [:service_message_map, service["ServiceNo"]]) == nil}}>
            <div class="next-bus" :if={{ Access.get(service, next_bus) != nil }} :for={{ next_bus <- ["NextBus", "NextBus2"] }}>
              <span class={{"indicator", "bg-yellow-1": service[next_bus]["Load"] in ["LSD", "SDA"], "bg-green-1": service[next_bus]["Load"] == "SEA"}}></span>
              <span class="badge" :if={{get_in(service, [next_bus, "isLastBus"]) == true}}>Last Bus</span>
              <span class="label">{{service[next_bus]["EstimatedArrival"] |> String.replace_suffix(" min", "")}}</span>
              <div class="bus-info-landscape">
                  <svg :if={{ service[next_bus]["Type"] == "DD" }} xmlns="http://www.w3.org/2000/svg" width="49.956" height="57.452" viewBox="0 0 49.956 57.452"><g dataName="Group 1696" transform="translate(0 0)"><path dataName="Path 134" d="M463.378,216.949h-.3a3.162,3.162,0,0,0-3.021-2.263v.844a2.329,2.329,0,0,1,2.144,1.425.967.967,0,0,0-.941.964v5.172a.97.97,0,0,0,.97.97h1.149a.97.97,0,0,0,.97-.97v-5.172A.969.969,0,0,0,463.378,216.949Z" transform="translate(-414.392 -191.275)" fill="#eee"></path><path dataName="Path 135" d="M448.058,188.484a114.169,114.169,0,0,0-34.261,0,3.566,3.566,0,0,0-3.555,3.556V210.6a3.164,3.164,0,0,0-3.021,2.263h-.3a.97.97,0,0,0-.97.97v5.172a.97.97,0,0,0,.97.97h1.15a.97.97,0,0,0,.97-.97v-5.172a.967.967,0,0,0-.94-.964,2.328,2.328,0,0,1,2.144-1.425v23.178a3.56,3.56,0,0,0,3.437,3.544v4.824a1.657,1.657,0,0,0,1.652,1.652h3.34a1.657,1.657,0,0,0,1.652-1.652V238.7a170.658,170.658,0,0,0,21.209,0v4.294a1.657,1.657,0,0,0,1.652,1.652h3.34a1.656,1.656,0,0,0,1.652-1.652v-4.824a3.561,3.561,0,0,0,3.438-3.544V192.04A3.566,3.566,0,0,0,448.058,188.484Zm-32.031,2.822a114.663,114.663,0,0,1,29.8,0,2.914,2.914,0,0,1,3.092,2.673v11.856H412.934V193.979A2.914,2.914,0,0,1,416.027,191.306Zm.884,42.661-3.425-.284a.307.307,0,0,1-.277-.251l-.215-1.2a.306.306,0,0,1,.327-.36l3.425.284a.306.306,0,0,1,.277.251l.215,1.2A.306.306,0,0,1,416.911,233.967Zm18.716,3.109a.287.287,0,0,1-.288.287h-8.826a.287.287,0,0,1-.287-.287v-1.421a.287.287,0,0,1,.287-.288h8.826a.288.288,0,0,1,.288.288Zm13.071-3.643a.3.3,0,0,1-.276.251l-3.426.284a.306.306,0,0,1-.327-.36l.215-1.2a.307.307,0,0,1,.277-.251l3.425-.284a.306.306,0,0,1,.327.36Zm-2.872-3.875a171.589,171.589,0,0,1-29.8,0,2.914,2.914,0,0,1-3.092-2.673V213.844h35.985v13.042A2.914,2.914,0,0,1,445.827,229.559Z" transform="translate(-405.949 -187.191)" fill="#eee"></path></g></svg>
                  <svg :if={{ service[next_bus]["Feature"] == "" }} xmlns="http://www.w3.org/2000/svg" width="42.989" height="42.989" viewBox="0 0 42.989 42.989"><g dataName="Group 1689" transform="translate(0 0)"><path dataName="Icon awesome-wheelchair" d="M23.991,18.65l.688,1.386a.774.774,0,0,1-.349,1.037l-3.166,1.59a1.548,1.548,0,0,1-2.089-.728l-3.036-6.461H9.285a1.548,1.548,0,0,1-1.532-1.329C6.114,2.675,6.208,3.387,6.19,3.095A3.095,3.095,0,1,1,9.738,6.157l.226,1.581h6.285a.774.774,0,0,1,.774.774v1.547a.774.774,0,0,1-.774.774H10.406l.221,1.547h6.4a1.547,1.547,0,0,1,1.4.889L21.2,19.189l1.75-.887a.774.774,0,0,1,1.037.349Zm-8.934-1.628H13.872A5.416,5.416,0,1,1,5.819,11.55L5.36,8.342A8.511,8.511,0,1,0,16.3,19.673Z" transform="translate(10.201 8.324)" fill="#eee"></path><g dataName="Ellipse 26" transform="translate(0 0)" fill="none" stroke="#eee" stroke-width="4"><circle cx="21.494" cy="21.494" r="21.494" stroke="none"></circle><circle cx="21.494" cy="21.494" r="19.494" fill="none"></circle></g><path dataName="Path 114" d="M-6200.484-9303.2l28.884,30.357" transform="translate(6207.76 9309.878)" fill="none" stroke="#eee" stroke-width="4"></path></g></svg>
                </div>
            </div>
            <div class="next-bus no-more" :if={{ get_in(service, ["NextBus"]) != nil and  get_in(service, ["NextBus", "isLastBus"]) == false and get_in(service, ["NextBus2"]) |> is_nil}}>
              <span class="label"></span>
            </div>
            <div class="next-bus no-more" :if={{ get_in(service, ["NextBus"]) != nil and  get_in(service, ["NextBus", "isLastBus"]) == true}}>
              <span class="label">No More Next Bus</span>
            </div>
            <div :if={{@is_bus_interchange == true}} class="berth">{{get_in(service, ["NextBus", "BerthLabel"])}}</div>
            <div class="destination-bus-stop">
              <p>{{service["NextBus"]["Destination"]}}</p>
              <div class="next-bus-station-with-tags">
                <div class="tags">
                  <div class="poi-wrapper" :if={{is_list(service["NextBus"]["DestinationPictograms"])}}>
                    <img :for={{ poi <- service["NextBus"]["DestinationPictograms"] }} src="{{poi}}" alt="">
                  </div>
                </div>
                <div :if={{not is_nil(service["NextBus"]["WayPoints"])}} class={{"text", "waypoint-wrapper", ticker: Utils.get_waypoints_length(service["NextBus"]["WayPoints"]) > 27}}>
                  <div class="waypoint" :for={{waypoint <- service["NextBus"]["WayPoints"]}}>
                    <span class="waypoint-text">
                      {{waypoint["text"]}}
                    </span>
                    <div class="tags">
                      <div class="poi-wrapper" :if={{is_list(waypoint["pictograms"])}}>
                        <img :for={{ poi <- waypoint["pictograms"] }} src="{{poi}}" alt="">
                      </div>
                    </div>
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
