defmodule DisplayWeb.Display do
  use Phoenix.LiveView
  import Surface
  require Logger
  alias Display.{RealTime, ScheduledAdhocMessage}

  def mount(%{"bus_stop_no" => bus_stop_no}, _session, socket) do
    socket =
      assign(socket,
        bus_stop_no: bus_stop_no,
        bus_stop_name: "TBD",
        stop_predictions: [],
        sheduled_message: nil
      )

    Process.send_after(self(), :update_stops, 0)
    Process.send_after(self(), :update_messages, 0)
    {:ok, socket}
  end

  def handle_info(:update_stops, socket) do
    case RealTime.get_predictions_cached(socket.assigns.bus_stop_no) do
      {:ok, cached_predictions} ->
        socket = assign(socket, :stop_predictions, cached_predictions)
        Process.send_after(self(), :update_stops, 60_000)
        {:noreply, socket}

      {:error, error} ->
        Logger.error("Error fetching cached_predictions #{inspect(error)}")
        Process.send_after(self(), :update_stops, 60_000)
        {:noreply, socket}
    end
  end

  def handle_info(:update_messages, socket) do
    message = ScheduledAdhocMessage.get_message(socket.assigns.bus_stop_no)
    socket = assign(socket, :sheduled_message, message)
    {:noreply, socket}
  end

  def format_to_mins(nil), do: ""

  def format_to_mins(time) do
    eta =
      time
      |> DateTime.from_iso8601()
      |> elem(1)
      |> Time.diff(DateTime.utc_now(), :second)

    cond do
      eta < 0 ->
        "Arr*"

      eta >= 0 and eta <= 20 ->
        "Arr"

      eta >= 20 and eta <= 60 ->
        "1 min"

      eta >= 3600 ->
        "> 60 min"

      true ->
        "#{ceil(eta / 60)} min"
    end
  end

  def render(assigns) do
    theme = "dark"

    ~H"""
    <div class="full-page-wrapper #{theme}">
      <ThreePaneALayout prop={{assigns}}/>
    </div>
    """
  end

  def render1(assigns) do
    ~L"""
    <div>
      <h1><%= @bus_stop %></h1>
    </div>

    <%= for service <- @stop_predictions do %>
    <table>
      <thead>
        <tr>
          <th></th>
          <th></th>
          <th></th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td style="font-weight: bold; font-size: 34px;"><%= service["ServiceNo"] %></td>
          <%= for next_bus <- ["NextBus", "NextBus2", "NextBus3"] do %>
            <td>
              <div>
                <div style="font-weight: bold; font-size: 24px;">
                  <%= service[next_bus]["EstimatedArrival"] |> format_to_mins %>
                </div>
                <div>
                  <%= service[next_bus]["Load"] %> |
                  <%= service[next_bus]["Feature"] %> |
                  <%= service[next_bus]["Type"] %>
                </div>
              </div>
          </td>
          <% end %>
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
