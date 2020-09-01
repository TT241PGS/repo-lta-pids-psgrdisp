defmodule DisplayWeb.Display do
  use Phoenix.LiveView
  alias Display.{RealTime, ScheduledAdhocMessage}

  def mount(%{"busstop" => bus_stop}, _session, socket) do
    socket = assign(socket, 
      bus_stop: bus_stop, 
      stop_predictions: [],
      sheduled_message: nil)
    Process.send_after(self(), :update_stops, 0)
    Process.send_after(self(), :update_messages, 0)
    {:ok, socket}
  end

  def handle_info(:update_stops, socket) do
    predictions = RealTime.get_predictions(socket.assigns.bus_stop)
    socket = assign(socket, :stop_predictions, predictions)
    Process.send_after(self(), :update_stops, 60_000)
    {:noreply, socket}
  end

  def handle_info(:update_messages, socket) do
    message = ScheduledAdhocMessage.get_message(socket.assigns.bus_stop)
    socket = assign(socket, :sheduled_message, message)
    {:noreply, socket}
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1>Bus Stop: <%= @bus_stop %></h1>
    </div>

    <%= for payment_method <- @stop_predictions do %>
    <table>
      <thead>
        <tr>
          <th>Service</th>
          <th>Arrival 1</th>
          <th>Arrival 2</th>
          <th>Arrival 3</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><%= payment_method["ServiceNo"] %></td>
          <td><%= payment_method["NextBus"]["EstimatedArrival"] %></td>
          <td><%= payment_method["NextBus2"]["EstimatedArrival"] %></td>
          <td><%= payment_method["NextBus3"]["EstimatedArrival"] %></td>
        </tr>
      </tbody>
    </table>
    <% end %>
    <div>
    <p><strong>Scheduled Message:</strong> <%= @sheduled_message %></p>
    </div>

    """
  end
end