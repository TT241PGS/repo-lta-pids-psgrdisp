defmodule Debug do
  @moduledoc false
  use Surface.LiveComponent

  property(prop, :map, default: %{})

  def render(assigns) do
    ~H"""
    <style>
      th, td {
        border: 1px solid #ffffff0d;
        padding: 10px;
      }
    </style>
    <div class="debug">
      <section>
        <h2>Schedule/Adhoc messages</h2>
        <section>
          <h3>Cycle Time (seconds)</h3>
          <p class="pl20">{{inspect(@prop.cycle_time)}}</p>
        </section>
        <section>
        <h3>Message Map (msg_index, msg_text)</h3>
        <p :for={{ {k, v} <- (@prop.messages.message_map || [])}}>
          <span class="pl20">{{k}}, {{inspect(v)}} </span>
        </p>
        </section>
        <section>
        <h3>Message Timeline (seconds, msg_index)</h3>
        <p class="pl20">{{inspect(@prop.messages.timeline)}}</p>
        </section>
      </section>
      <section>
        <h2>Suppressed Messages</h2>
        <p>{{inspect(@prop.suppressed_messages)}}</p>
      </section>
      <section>
        <h2>Layout Mode</h2>
        <p>{{inspect(@prop.layout_mode)}}</p>
      </section>
      <section>
        <h2>QWT Candidates</h2>
        <table>
          <tr>
            <th>POI Code</th>
            <th>Service</th>
            <th>Direction</th>
            <th>Visit No</th>
            <th>Arriving Time at Source</th>
            <th>Arriving Time at POI</th>
            <th>Travel Time</th>
          </tr>
          <tbody :for={{ {poi_code, services} <- @prop.quickest_way_to_candidates}}>
            <tr :for={{ service <- services}}>
              <td>{{poi_code}}</td>
              <td>{{get_in(service, ["service_no"])}}</td>
              <td>{{get_in(service, ["direction"])}}</td>
              <td>{{get_in(service, ["visit_no"])}}</td>
              <td>{{get_in(service, ["arriving_time_at_origin"])}}</td>
              <td>{{get_in(service, ["arriving_time_at_destination"])}}</td>
              <td>{{get_in(service, ["travel_time"])}}</td>
            </tr>
          </tbody>
        </table>
      </section>
    </div>
    """
  end
end
