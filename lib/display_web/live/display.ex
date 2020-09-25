defmodule DisplayWeb.Display do
  @moduledoc false
  use Phoenix.LiveView
  import Surface
  require Logger
  alias Display.{Buses, Messages, RealTime, Templates}

  defp get_template_details_from_cms(panel_id) do
    Templates.list_templates_by_panel_id(panel_id)
    |> Enum.map(fn template ->
      template
      |> get_in([:template_detail])
      |> Jason.decode!()
    end)
  end

  def mount(%{"panel_id" => panel_id}, _session, socket) do
    socket =
      assign(socket,
        bus_stop_no: nil,
        bus_stop_name: "Bus stop name #",
        panel_id: panel_id,
        current_layout_value: nil,
        current_layout_index: nil,
        current_layout_panes: nil,
        stop_predictions_set_1_column: [],
        stop_predictions_set_2_column: [],
        messages: []
      )

    Process.send_after(self(), :update_stops, 0)
    Process.send_after(self(), :update_messages, 0)
    Process.send_after(self(), :update_layout, 0)
    {:ok, socket}
  end

  def handle_info(:update_stops, socket) do
    bus_stop_no =
      Templates.get_bus_stop_from_panel_id(socket.assigns.panel_id)
      |> get_in([:bus_stop_no])

    bus_stop_name = Buses.get_bus_stop_name_by_no(bus_stop_no)

    socket =
      socket
      |> assign(:bus_stop_no, bus_stop_no)
      |> assign(:bus_stop_name, bus_stop_name)

    case RealTime.get_predictions_cached(bus_stop_no) do
      {:ok, cached_predictions} ->
        cached_predictions =
          cached_predictions
          |> Flow.from_enumerable()
          |> Flow.map(fn service ->
            service
            |> update_estimated_arrival("NextBus")
            |> update_estimated_arrival("NextBus2")
            |> update_estimated_arrival("NextBus3")
          end)
          |> Enum.sort_by(fn p -> p["ServiceNo"] |> String.to_integer() end)

        bus_stop_map =
          cached_predictions
          |> Enum.map(fn service ->
            service
            |> get_in(["NextBus", "DestinationCode"])
          end)
          |> Buses.get_bus_stop_map_by_nos()

        cached_predictions =
          cached_predictions
          |> Enum.map(fn service ->
            service
            |> update_destination(bus_stop_map)
          end)

        socket =
          socket
          |> assign(
            :stop_predictions_set_1_column,
            create_stop_predictions_set_1_column(cached_predictions)
          )
          |> assign(
            :stop_predictions_set_2_column,
            create_stop_predictions_set_2_column(cached_predictions)
          )

        Process.send_after(self(), :update_stops, 20_000)
        {:noreply, socket}

      {:error, error} ->
        Logger.error("Error fetching cached_predictions #{inspect(error)}")
        Process.send_after(self(), :update_stops, 20_000)
        {:noreply, socket}
    end
  end

  defp create_stop_predictions_set_1_column(cached_predictions) do
    create_stop_predictions_columnwise(cached_predictions, 5)
  end

  defp create_stop_predictions_set_2_column(cached_predictions) do
    create_stop_predictions_columnwise(cached_predictions, 10)
  end

  defp create_stop_predictions_columnwise(cached_predictions, max_rows) do
    cached_predictions
    |> Enum.with_index()
    |> Enum.reduce([], fn {prediction, index}, acc ->
      remainder = rem(index, max_rows)
      quotient = div(index, max_rows)

      if remainder == 0,
        do: List.insert_at(acc, quotient, [prediction]),
        else: List.update_at(acc, quotient, &(&1 ++ [prediction]))
    end)
  end

  defp update_estimated_arrival(service, next_bus) do
    case Access.get(service, next_bus) do
      nil -> service
      _ -> update_in(service, [next_bus, "EstimatedArrival"], &format_to_mins(&1))
    end
  end

  defp update_destination(service, bus_stop_map) do
    case Access.get(service, "NextBus") do
      nil ->
        service

      _ ->
        update_in(
          service,
          ["NextBus", "DestinationCode"],
          &Buses.get_bus_stop_name_from_bus_stop_map(bus_stop_map, &1 |> String.to_integer())
        )
    end
  end

  def handle_info(:update_messages, socket) do
    messages = Messages.get_messages(socket.assigns.panel_id)
    socket = assign(socket, :messages, messages)
    Process.send_after(self(), :update_messages, 10_000)
    Process.send_after(self(), :update_layout, 0)
    {:noreply, socket}
  end

  def handle_info(:update_layout, socket) do
    templates = get_template_details_from_cms(socket.assigns.panel_id)

    # If messages are present, show template A
    elected_template_index = if length(socket.assigns.messages) > 0, do: 0, else: 1

    layouts = templates |> Enum.at(elected_template_index) |> Map.get("layouts")

    case socket.assigns.current_layout_index do
      nil ->
        next_layout = Enum.at(layouts, 0)

        socket =
          assign(socket, :current_layout_value, Map.get(next_layout, "value"))
          |> assign(:current_layout_index, 0)
          |> assign(:current_layout_panes, Map.get(next_layout, "panes"))

        Process.send_after(
          self(),
          :update_layout,
          Map.get(next_layout, "duration") * 1000
        )

        {:noreply, socket}

      current_index ->
        next_index = get_next_index(layouts, current_index)
        next_layout = Enum.at(layouts, next_index)

        socket =
          assign(socket, :current_layout_value, Map.get(next_layout, "value"))
          |> assign(:current_layout_index, next_index)
          |> assign(:current_layout_panes, Map.get(next_layout, "panes"))

        Process.send_after(
          self(),
          :update_layout,
          Map.get(next_layout, "duration") * 1000
        )

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

      "landscape_two_pane_b" ->
        ~H"""
        <div class="full-page-wrapper #{theme}">
          <LandscapeTwoPaneBLayout prop={{assigns}}/>
        </div>
        """

      nil ->
        ~H"""
        <div class="full-page-wrapper #{theme}">
        <div style="font-size: 30px;text-align: center;color: white;margin-top: 50px;">Loading...</div>
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
