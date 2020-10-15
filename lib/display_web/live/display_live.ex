defmodule DisplayWeb.DisplayLive do
  @moduledoc false
  use Phoenix.LiveView
  import Surface
  require Logger
  alias Display.{Buses, Messages, RealTime, Templates}
  alias Display.Utils.{DisplayLiveUtil, TimeUtil}

  def mount(%{"panel_id" => panel_id}, _session, socket) do
    start_time = Timex.now()
    Logger.info("Mount started")

    socket =
      assign(socket,
        bus_stop_no: nil,
        bus_stop_name: "Bus stop name #",
        panel_id: panel_id,
        current_layout_value: nil,
        current_layout_index: nil,
        current_layout_panes: nil,
        is_multi_layout: false,
        stop_predictions_realtime_set_1_column: [],
        stop_predictions_scheduled_set_1_column: [],
        incoming_buses: [],
        stop_predictions_realtime_set_2_column: [],
        stop_predictions_scheduled_set_2_column: [],
        messages: []
      )

    if connected?(socket), do: DisplayWeb.Endpoint.subscribe("poller")

    Process.send_after(self(), :update_stops, 0)
    Process.send_after(self(), :update_messages, 0)
    Process.send_after(self(), :update_layout, 0)
    elapsed_time = TimeUtil.get_elapsed_time(start_time)
    Logger.info("Mount ended (#{elapsed_time})")
    {:ok, socket}
  end

  def handle_info(:update_stops, socket) do
    start_time = Timex.now()
    Logger.info(":update_stops started")

    bus_stop_no =
      Buses.get_bus_stop_from_panel_id(socket.assigns.panel_id)
      |> get_in([:bus_stop_no])

    bus_stop_name = Buses.get_bus_stop_name_by_no(bus_stop_no)

    socket =
      socket
      |> assign(:bus_stop_no, bus_stop_no)
      |> assign(:bus_stop_name, bus_stop_name)

    case RealTime.get_predictions_cached(bus_stop_no) do
      {:ok, cached_predictions} ->
        incoming_buses = DisplayLiveUtil.get_incoming_buses(cached_predictions)

        cached_predictions = DisplayLiveUtil.update_cached_predictions(cached_predictions)

        socket =
          socket
          |> assign(
            :stop_predictions_realtime_set_1_column,
            DisplayLiveUtil.create_stop_predictions_set_1_column(cached_predictions)
          )
          |> assign(
            :stop_predictions_realtime_set_2_column,
            DisplayLiveUtil.create_stop_predictions_set_2_column(cached_predictions)
          )
          |> assign(
            :incoming_buses,
            incoming_buses
          )

        Process.send_after(self(), :update_stops, 30_000)
        elapsed_time = TimeUtil.get_elapsed_time(start_time)
        Logger.info(":update_stops ended successfully (#{elapsed_time})")
        {:noreply, socket}

      {:error, :not_found} ->
        Logger.error(
          "Cached_predictions :not_found for bus stop: #{inspect({bus_stop_no, bus_stop_name})}"
        )

        # TODO remove hardcoded bus stop no
        scheduled_predictions = Display.Scheduled.get_predictions(1019)

        # TODO incoming buses

        scheduled_predictions =
          DisplayLiveUtil.update_scheduled_predictions(scheduled_predictions)

        socket =
          socket
          |> assign(:stop_predictions_realtime_set_1_column, [])
          |> assign(:stop_predictions_realtime_set_2_column, [])
          |> assign(
            :stop_predictions_scheduled_set_1_column,
            DisplayLiveUtil.create_stop_predictions_set_1_column(scheduled_predictions)
          )
          |> assign(
            :stop_predictions_scheduled_set_2_column,
            DisplayLiveUtil.create_stop_predictions_set_2_column(scheduled_predictions)
          )

        Process.send_after(self(), :update_stops, 30_000)
        elapsed_time = TimeUtil.get_elapsed_time(start_time)
        Logger.info(":update_stops failed (#{elapsed_time})")
        {:noreply, socket}

      {:error, error} ->
        Logger.error(
          "Error fetching cached_predictions for bus stop: #{
            inspect({bus_stop_no, bus_stop_name})
          } -> #{inspect(error)}"
        )

        Process.send_after(self(), :update_stops, 30_000)
        elapsed_time = TimeUtil.get_elapsed_time(start_time)
        Logger.info(":update_stops failed (#{elapsed_time})")
        {:noreply, socket}
    end
  end

  def handle_info(:update_messages, socket) do
    start_time = Timex.now()
    Logger.info(":update_messages started")
    messages = Messages.get_messages(socket.assigns.panel_id)
    socket = assign(socket, :messages, messages)
    Process.send_after(self(), :update_messages, 10_000)
    elapsed_time = TimeUtil.get_elapsed_time(start_time)
    Logger.info(":update_messages ended successfully (#{elapsed_time})")
    {:noreply, socket}
  end

  def handle_info(:update_layout, socket) do
    start_time = Timex.now()

    Logger.info(":update_layout started")
    templates = DisplayLiveUtil.get_template_details_from_cms(socket.assigns.panel_id)

    # If messages are present, show template A
    elected_template_index = if length(socket.assigns.messages) > 0, do: 0, else: 1

    layouts = templates |> Enum.at(elected_template_index) |> Map.get("layouts")

    is_multi_layout = if length(layouts) > 1, do: true, else: false

    socket = assign(socket, :is_multi_layout, is_multi_layout)

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

        elapsed_time = TimeUtil.get_elapsed_time(start_time)
        Logger.info(":update_layout ended successfully (#{elapsed_time})")

        {:noreply, socket}

      current_index ->
        next_index = DisplayLiveUtil.get_next_index(layouts, current_index)
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

        elapsed_time = TimeUtil.get_elapsed_time(start_time)
        Logger.info(":update_layout ended successfully (#{elapsed_time})")

        {:noreply, socket}
    end
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "arrival_predictions_updated",
          payload: %{},
          topic: "poller"
        },
        socket
      ) do
    Process.send_after(self(), :update_stops, 0)
    {:noreply, socket}
  end

  def render(assigns) do
    theme = "dark"

    is_multi_layout = assigns.is_multi_layout

    case assigns.current_layout_value do
      "landscape_one_pane" ->
        ~H"""
        <div class={{"full-page-wrapper #{theme} hide", "multi-layout": is_multi_layout == true}}>
          <LandscapeOnePaneLayout prop={{assigns}}/>
        </div>
        """

      "landscape_two_pane_b" ->
        ~H"""
        <div class={{"full-page-wrapper #{theme} hide", "multi-layout": is_multi_layout == true}}>
          <LandscapeTwoPaneBLayout prop={{assigns}}/>
        </div>
        """

      "landscape_three_pane_a" ->
        ~H"""
        <div class={{"full-page-wrapper #{theme} hide", "multi-layout": is_multi_layout == true}}>
          <LandscapeThreePaneALayout prop={{assigns}}/>
        </div>
        """

      nil ->
        ~H"""
        <div class={{"full-page-wrapper #{theme} hide", "multi-layout": is_multi_layout == true}}>
        <div style="font-size: 30px;text-align: center;color: white;margin-top: 50px;">Loading...</div>
        </div>
        """

      unknown_layout ->
        ~H"""
        <div class={{"full-page-wrapper #{theme} hide", "multi-layout": is_multi_layout == true}}>
        <div style="font-size: 30px;text-align: center;color: white;margin-top: 50px;">Layout "{{unknown_layout}}" not implemented</div>
        </div>
        """
    end
  end
end
