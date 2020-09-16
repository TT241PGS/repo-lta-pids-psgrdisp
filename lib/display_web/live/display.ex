defmodule DisplayWeb.Display do
  @moduledoc false
  use Phoenix.LiveView
  import Surface
  require Logger
  alias Display.{RealTime, ScheduledAdhocMessage}

  defp get_template_details_from_cms(panel_id) do
    "{\"orientation\":{\"label\":\"Landscape\",\"value\":\"landscape\"},\"templates\":[{\"label\":\"One-Pane Layout\",\"value\":\"landscape_one_pane\",\"duration\":10,\"id\":\"landscape_one_pane_0\",\"chosen\":false,\"selected\":false,\"panes\":{\"pane1\":{\"type\":{\"value\":\"predictions_by_service\",\"label\":\"Predictions and Points of Interest by Service\",\"description\":\"Lorem ipsum dolor sit amet, consectetur adipisicing elit. Accusantium hic optio tempora harum placeat itaque a architecto exercitationem atque soluta ducimus, esse, laboriosam adipisci, quam ut! Necessitatibus aperiam architecto quis. \"},\"config\":{\"font\":{\"style\":\"monospace\",\"color\":\"red\"}}}}},{\"label\":\"Two-Pane Layout A\",\"value\":\"landscape_two_pane_a\",\"duration\":10,\"id\":\"landscape_two_pane_a_1\",\"chosen\":false,\"selected\":false,\"panes\":{\"pane1\":{\"type\":{\"value\":\"quickest_way_to\",\"label\":\"Quickest Way To\"},\"config\":{\"font\":{\"style\":\"sans-serif\",\"color\":\"blue\"}}},\"pane2\":{\"type\":{\"value\":\"scheduled_and_ad_hoc_messages\",\"label\":\"Scheduled and ad-hoc messages\"},\"config\":{\"scheduled_messages_font\":{\"style\":\"monospace\",\"color\":\"green\"},\"adhoc_messages_font\":{\"style\":\"sans-serif\",\"color\":\"green\"}}}}}]}"
    |> Jason.decode!()
  end

  def mount(%{"bus_stop_no" => bus_stop_no}, _session, socket) do
    socket =
      assign(socket,
        bus_stop_no: bus_stop_no,
        bus_stop_name: "Bus stop name #",
        panel_id: "dummy-panel-id",
        current_layout_value: nil,
        current_layout_index: nil,
        current_layout_panes: nil,
        stop_predictions: [],
        sheduled_message: nil
      )

    Process.send_after(self(), :update_stops, 0)    
    Process.send_after(self(), :update_messages, 0)
    Process.send_after(self(), :update_layout, 0)
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
        Process.send_after(self(), :update_stops, 20_000)
        {:noreply, socket}

      {:error, error} ->
        Logger.error("Error fetching cached_predictions #{inspect(error)}")
        Process.send_after(self(), :update_stops, 20_000)
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

  def handle_info(:update_layout, socket) do
    template_details = get_template_details_from_cms(socket.assigns.panel_id)
    layouts = Map.get(template_details, "templates")

    case socket.assigns.current_layout_index do
      nil ->
        next_layout = Enum.at(layouts, 0)

        socket =
          assign(socket, :current_layout_value, Map.get(next_layout, "value"))
          |> assign(:current_layout_index, 0)
          |> assign(:current_layout_panes, Map.get(next_layout, "panes"))

        Process.send_after(self(), :update_layout, Map.get(next_layout, "duration") * 1000)

        {:noreply, socket}

      current_index ->
        next_index = get_next_index(layouts, current_index)
        next_layout = Enum.at(layouts, next_index)

        socket =
          assign(socket, :current_layout_value, Map.get(next_layout, "value"))
          |> assign(:current_layout_index, next_index)
          |> assign(:current_layout_panes, Map.get(next_layout, "panes"))

        Process.send_after(self(), :update_layout, Map.get(next_layout, "duration") * 1000)

        {:noreply, socket}
    end
  end

  defp get_next_index(layouts, current_index) do
    max_index = length(layouts) - 1

    cond do
      current_index < max_index -> current_index + 1
      current_index == max_index -> 0
      true -> 0
    end
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

    case assigns.current_layout_value do
      "landscape_one_pane" ->
        ~H"""
        <div class="full-page-wrapper #{theme}">
          <LandscapeOnePaneLayout prop={{assigns}}/>
        </div>
        """

      unknown_layout ->
        ~H"""
        <div class="full-page-wrapper #{theme}">
        <div style="font-size: 30px;text-align: center;color: white;margin-top: 50px;">Layout "{{unknown_layout}}" not implemented</div>
        </div>
        """
    end
  end
end
