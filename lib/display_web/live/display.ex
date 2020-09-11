defmodule DisplayWeb.Display do
  @moduledoc false
  use Phoenix.LiveView
  import Surface
  require Logger
  alias Display.{RealTime, ScheduledAdhocMessage}

  def mount(%{"bus_stop_no" => bus_stop_no}, _session, socket) do
    socket =
      assign(socket,
        bus_stop_no: bus_stop_no,
        bus_stop_name: "Bus stop name #",
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
        cached_predictions =
          Enum.map(cached_predictions, fn service ->
            service
            |> update_estimated_arrival("NextBus")
            |> update_estimated_arrival("NextBus2")
            |> update_estimated_arrival("NextBus3")
          end)

        socket = assign(socket, :stop_predictions, cached_predictions)
        Process.send_after(self(), :update_stops, 60_000)
        {:noreply, socket}

      {:error, error} ->
        Logger.error("Error fetching cached_predictions #{inspect(error)}")
        Process.send_after(self(), :update_stops, 60_000)
        {:noreply, socket}
    end
  end

  defp update_estimated_arrival(nil), do: ""

  defp update_estimated_arrival(service, next_bus) do
    case Access.get(service, next_bus) do
      nil -> service
      _ -> update_in(service, [next_bus, "EstimatedArrival"], &format_to_mins(&1))
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
end
