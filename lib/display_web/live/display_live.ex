defmodule DisplayWeb.DisplayLive do
  @moduledoc false
  use Phoenix.LiveView
  import Surface
  require Logger
  alias Display.{Buses, Messages}
  alias Display.Utils.{DisplayLiveUtil, TimeUtil}
  # prediction page switching frequency in seconds
  @slider_speed 5

  def mount(
        %{"panel_id" => panel_id} = assigns,
        _session,
        socket
      ) do
    start_time = Timex.now()
    Logger.info("Mount started")

    socket =
      assign(socket,
        panel_id: panel_id,
        skip_realtime: assigns["skip_realtime"] || false,
        debug: assigns["debug"] || false,
        date_time: TimeUtil.get_display_date_time(),
        bus_stop_no: nil,
        bus_stop_name: "",
        templates: [],
        current_layouts: nil,
        current_layout_value: nil,
        current_layout_index: nil,
        current_layout_panes: nil,
        update_layout_timer: nil,
        is_multi_layout: false,
        incoming_buses: [],
        predictions_previous: [],
        predictions_current: [],
        predictions_realtime_set_1_column: [],
        predictions_realtime_set_2_column: [],
        predictions_realtime_set_1_column_index: nil,
        predictions_realtime_set_2_column_index: nil,
        predictions_scheduled_set_1_column: [],
        predictions_scheduled_set_2_column: [],
        predictions_scheduled_set_1_column_index: nil,
        predictions_scheduled_set_2_column_index: nil,
        is_prediction_next_slide_scheduled: false,
        messages: %{message_map: nil, timeline: nil},
        suppressed_messages: %{global_message: nil, service_message_map: %{}, hide_services: []},
        previous_messages: %{message_map: nil, timeline: nil},
        message_list_index: nil,
        message_timeline_index: nil,
        message: "",
        cycle_time: nil,
        quickest_way_to: [],
        is_show_non_message_template: false,
        update_messages_timeline_timer: nil,
        multimedia: %{content: nil, type: nil},
        multimedia_image_sequence_next_trigger_at: nil,
        multimedia_image_sequence_current_index: nil,
        multimedia_image_sequence_current_url: nil
      )

    case Process.get(:"$callers") do
      nil -> ""
      callers -> Cachex.put(:display, List.last(callers), assigns["scheduled_date_time"])
    end

    if connected?(socket), do: DisplayWeb.Endpoint.subscribe("poller")

    Process.send_after(self(), :update_stops_repeatedly, 0)
    Process.send_after(self(), :update_messages_repeatedly, 0)
    Process.send_after(self(), :update_layout_repeatedly, 0)
    Process.send_after(self(), :update_time_repeatedly, 0)
    elapsed_time = TimeUtil.get_elapsed_time(start_time)
    Logger.info("Mount ended (#{elapsed_time})")
    {:ok, socket}
  end

  @doc """
    This is called after "arrival_predictions_updated" broadcast event
    This does not schedule update stops to be called after certain period again
  """
  def handle_info(:update_stops_once, socket) do
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

    %{
      skip_realtime: skip_realtime,
      is_prediction_next_slide_scheduled: is_prediction_next_slide_scheduled
    } = socket.assigns

    case skip_realtime do
      "true" ->
        DisplayLiveUtil.show_scheduled_predictions(
          socket,
          bus_stop_no,
          start_time,
          false,
          is_prediction_next_slide_scheduled
        )

      _ ->
        DisplayLiveUtil.get_realtime_or_scheduled_predictions(
          socket,
          bus_stop_no,
          bus_stop_name,
          start_time,
          false,
          is_prediction_next_slide_scheduled
        )
    end
  end

  @doc """
    This calls itself after certain period of time to update stops every n seconds
  """
  def handle_info(:update_stops_repeatedly, socket) do
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

    %{
      skip_realtime: skip_realtime,
      is_prediction_next_slide_scheduled: is_prediction_next_slide_scheduled
    } = socket.assigns

    case skip_realtime do
      "true" ->
        DisplayLiveUtil.show_scheduled_predictions(
          socket,
          bus_stop_no,
          start_time,
          true,
          is_prediction_next_slide_scheduled
        )

      _ ->
        DisplayLiveUtil.get_realtime_or_scheduled_predictions(
          socket,
          bus_stop_no,
          bus_stop_name,
          start_time,
          true,
          is_prediction_next_slide_scheduled
        )
    end
  end

  @doc """
    This calls itself after certain period of time to update time
  """
  def handle_info(:update_time_repeatedly, socket) do
    socket =
      socket
      |> assign(:date_time, TimeUtil.get_display_date_time())

    Process.send_after(self(), :update_time_repeatedly, 30_000)

    {:noreply, socket}
  end

  def handle_info(:update_predictions_slider, socket) do
    start_time = Timex.now()
    Logger.info(":update_predictions_slider started")

    %{
      predictions_realtime_set_1_column: predictions_realtime_set_1_column,
      predictions_realtime_set_2_column: predictions_realtime_set_2_column,
      predictions_realtime_set_1_column_index: predictions_realtime_set_1_column_index,
      predictions_realtime_set_2_column_index: predictions_realtime_set_2_column_index,
      predictions_scheduled_set_1_column: predictions_scheduled_set_1_column,
      predictions_scheduled_set_2_column: predictions_scheduled_set_2_column,
      predictions_scheduled_set_1_column_index: predictions_scheduled_set_1_column_index,
      predictions_scheduled_set_2_column_index: predictions_scheduled_set_2_column_index
    } = socket.assigns

    next_trigger_after =
      cond do
        length(predictions_realtime_set_1_column) > 0 ->
          @slider_speed

        length(predictions_realtime_set_2_column) > 0 ->
          @slider_speed

        length(predictions_scheduled_set_1_column) > 0 ->
          @slider_speed

        length(predictions_scheduled_set_2_column) > 0 ->
          @slider_speed

        true ->
          nil
      end

    socket =
      unless is_nil(next_trigger_after) do
        Process.send_after(self(), :update_predictions_slider, next_trigger_after * 1000)
        assign(socket, :is_prediction_next_slide_scheduled, true)
      else
        assign(socket, :is_prediction_next_slide_scheduled, false)
      end

    elapsed_time = TimeUtil.get_elapsed_time(start_time)
    Logger.info(":update_predictions_slider ended successfully (#{elapsed_time})")

    socket =
      socket
      |> assign(
        :predictions_realtime_set_1_column_index,
        determine_prediction_next_index(
          predictions_realtime_set_1_column,
          predictions_realtime_set_1_column_index
        )
      )
      |> assign(
        :predictions_realtime_set_2_column_index,
        determine_prediction_next_index(
          predictions_realtime_set_2_column,
          predictions_realtime_set_2_column_index
        )
      )
      |> assign(
        :predictions_scheduled_set_1_column_index,
        determine_prediction_next_index(
          predictions_scheduled_set_1_column,
          predictions_scheduled_set_1_column_index
        )
      )
      |> assign(
        :predictions_scheduled_set_2_column_index,
        determine_prediction_next_index(
          predictions_scheduled_set_2_column,
          predictions_scheduled_set_2_column_index
        )
      )

    {:noreply, socket}
  end

  defp determine_prediction_next_index(list, index) do
    cond do
      length(list) == 0 ->
        nil

      index == nil ->
        0

      index == length(list) - 1 ->
        0

      true ->
        index + 1
    end
  end

  @doc """
    This calls itself after certain period of time to update messages/advisories every n seconds
  """
  def handle_info(:update_messages_repeatedly, socket) do
    start_time = Timex.now()
    Logger.info(":update_messages_repeatedly started")
    previous_messages = socket.assigns.messages
    cycle_time = socket.assigns.cycle_time
    new_messages = Messages.get_messages(socket.assigns.panel_id)

    new_messages =
      new_messages
      |> Enum.map(fn %{message_content: text, priority: pm} ->
        %{text: text, pm: pm}
      end)

    cycle_time = if cycle_time == nil, do: 300, else: cycle_time

    start_time1 = Timex.now()
    new_messages = Messages.get_message_timings(new_messages, cycle_time)
    elapsed_time1 = TimeUtil.get_elapsed_time(start_time1)
    Logger.info(":get_message_timings ended successfully (#{elapsed_time1})")

    socket =
      socket
      |> assign(:previous_messages, previous_messages)
      |> assign(:messages, new_messages)
      |> assign(:cycle_time, cycle_time)

    unless new_messages.timeline == nil or previous_messages == new_messages do
      Process.send_after(self(), :update_messages_timeline, 100)
    end

    Process.send_after(self(), :update_messages_repeatedly, 10_000)
    elapsed_time = TimeUtil.get_elapsed_time(start_time)
    Logger.info(":update_messages_repeatedly ended successfully (#{elapsed_time})")
    {:noreply, socket}
  end

  @doc """
    This is called only when there are messages for a panel in order to cycle through messages
  """
  # messages: [],
  # previous_messages: [],
  # message_list_index: nil,
  # message_timeline_index: nil,
  def handle_info(:update_messages_timeline, socket) do
    start_time = Timex.now()
    Logger.info(":update_messages_timeline started")

    %{
      messages: %{timeline: timeline, message_map: message_map},
      message_timeline_index: message_timeline_index,
      update_messages_timeline_timer: update_messages_timeline_timer
    } = socket.assigns

    timeline_length = length(timeline)
    timeline_last_index = timeline_length - 1

    new_message_timeline_index =
      cond do
        timeline_length == 0 ->
          nil

        message_timeline_index == nil ->
          0

        message_timeline_index == timeline_last_index ->
          0

        true ->
          message_timeline_index + 1
      end

    next_message_timeline_index =
      cond do
        timeline_length == 0 ->
          nil

        new_message_timeline_index == nil ->
          nil

        new_message_timeline_index == timeline_last_index ->
          0

        true ->
          new_message_timeline_index + 1
      end

    next_trigger_at =
      cond do
        is_nil(next_message_timeline_index) ->
          nil

        message_timeline_index == timeline_last_index and next_message_timeline_index == 1 ->
          socket.assigns.cycle_time

        true ->
          Enum.at(timeline, next_message_timeline_index) |> elem(0)
      end

    next_trigger_after =
      cond do
        length(timeline) > 0 and is_nil(message_timeline_index) ->
          next_trigger_at

        next_trigger_at == 0 ->
          previous_timeline = Enum.at(timeline, new_message_timeline_index) |> elem(0)
          socket.assigns.cycle_time - previous_timeline

        next_trigger_at == socket.assigns.cycle_time ->
          1

        message_timeline_index >= 0 ->
          previous_timeline = Enum.at(timeline, new_message_timeline_index) |> elem(0)
          next_trigger_at - previous_timeline

        true ->
          next_trigger_at
      end

    message_list_index =
      if new_message_timeline_index >= 0,
        do: Enum.at(timeline, new_message_timeline_index) |> elem(1),
        else: nil

    message =
      if message_list_index >= 0,
        do: message_map[message_list_index],
        else: ""

    if not is_nil(next_trigger_at) and not is_nil(update_messages_timeline_timer) do
      Process.cancel_timer(update_messages_timeline_timer)
    end

    update_messages_timeline_timer =
      unless is_nil(next_trigger_at) do
        Process.send_after(self(), :update_messages_timeline, next_trigger_after * 1000)
      end

    socket =
      if new_message_timeline_index == timeline_last_index and message_list_index == nil do
        socket = socket |> assign(:is_show_non_message_template, true)

        %{templates: templates, current_layout_index: current_layout_index} = socket.assigns
        layouts = templates |> Enum.at(0) |> Map.get("layouts")

        DisplayLiveUtil.update_layout(socket, layouts, current_layout_index) |> elem(1)
      else
        socket |> assign(:is_show_non_message_template, false)

        %{templates: templates, current_layout_index: current_layout_index} = socket.assigns
        layouts = templates |> Enum.at(1) |> Map.get("layouts")

        DisplayLiveUtil.update_layout(socket, layouts, current_layout_index) |> elem(1)
      end

    socket =
      socket
      |> assign(:message_list_index, message_list_index)
      |> assign(:message_timeline_index, new_message_timeline_index)
      |> assign(:message, message)
      |> assign(:update_messages_timeline_timer, update_messages_timeline_timer)

    elapsed_time = TimeUtil.get_elapsed_time(start_time)
    Logger.info(":update_messages_timeline ended successfully (#{elapsed_time})")

    {:noreply, socket}
  end

  def handle_info(
        :show_next_image_sequence,
        %{
          assigns: %{
            multimedia: %{type: type}
          }
        } = socket
      )
      when type != "IMAGE SEQUENCE" do
    {:noreply, socket}
  end

  def handle_info(:show_next_image_sequence, socket) do
    %{
      multimedia: multimedia,
      multimedia_image_sequence_current_index: multimedia_image_sequence_current_index
    } = socket.assigns

    max_index = length(multimedia.content) - 1

    next_index =
      cond do
        is_nil(multimedia_image_sequence_current_index) ->
          0

        multimedia_image_sequence_current_index >= max_index ->
          0

        true ->
          multimedia_image_sequence_current_index + 1
      end

    next_slide = Enum.at(multimedia.content, next_index)

    next_slide_url = Map.get(next_slide, "url")

    next_trigger_at = Map.get(next_slide, "duration") |> String.to_integer()

    case socket.assigns.multimedia_image_sequence_next_trigger_at do
      nil -> nil
      timer_ref -> Process.cancel_timer(timer_ref)
    end

    multimedia_image_sequence_next_trigger_at =
      Process.send_after(self(), :show_next_image_sequence, next_trigger_at * 1000)

    socket =
      socket
      |> assign(:multimedia_image_sequence_current_index, next_index)
      |> assign(:multimedia_image_sequence_current_url, next_slide_url)
      |> assign(
        :multimedia_image_sequence_next_trigger_at,
        multimedia_image_sequence_next_trigger_at
      )

    {:noreply, socket}
  end

  @doc """
    This calls itself after certain period of time to update layout every n seconds
  """
  def handle_info(:update_layout_repeatedly, socket) do
    start_time = Timex.now()

    Logger.info(":update_layout_repeatedly started")

    templates =
      DisplayLiveUtil.get_template_details_from_cms(socket.assigns.panel_id)
      |> DisplayLiveUtil.discard_inactive_multimedia_layouts()

    socket = socket |> assign(:templates, templates)

    %{
      messages: messages,
      current_layout_index: current_layout_index,
      is_show_non_message_template: is_show_non_message_template
    } = socket.assigns

    template_index =
      cond do
        is_show_non_message_template == true ->
          0

        # If messages are not present, show template A
        is_nil(messages.timeline) ->
          0

        # If messages are present, show template B
        true ->
          1
      end

    # FOR DEVELOPMENT ONLY, not supposed to be commited
    # template_index = 0

    layouts = templates |> Enum.at(template_index) |> Map.get("layouts")

    message_layouts = templates |> Enum.at(1) |> Map.get("layouts")

    cycle_time = DisplayLiveUtil.get_cycle_time_from_layouts(message_layouts)

    socket =
      socket
      |> assign(:cycle_time, cycle_time)

    result = DisplayLiveUtil.update_layout(socket, layouts, current_layout_index)

    elapsed_time = TimeUtil.get_elapsed_time(start_time)
    Logger.info(":update_layout_repeatedly ended successfully (#{elapsed_time})")

    result
  end

  def handle_info(:show_next_layout, socket) do
    start_time = Timex.now()

    %{current_layouts: current_layouts, current_layout_index: current_layout_index} =
      socket.assigns

    next_index =
      case current_layout_index do
        nil ->
          0

        current_index ->
          DisplayLiveUtil.get_next_index(current_layouts, current_index)
      end

    next_layout = Enum.at(current_layouts, next_index)
    next_duration = Map.get(next_layout, "duration") |> String.to_integer()

    multimedia = DisplayLiveUtil.get_multimedia(next_layout)

    socket = DisplayLiveUtil.reset_image_sequence_slider_maybe(multimedia, socket)

    update_layout_prev_timer = socket.assigns.update_layout_timer

    case update_layout_prev_timer do
      nil -> nil
      timer_ref -> Process.cancel_timer(timer_ref)
    end

    update_layout_timer =
      Process.send_after(
        self(),
        :update_layout_repeatedly,
        next_duration * 1000
      )

    Process.send_after(
      self(),
      :show_next_layout,
      next_duration * 1000
    )

    socket =
      socket
      |> Phoenix.LiveView.assign(:current_layout_value, Map.get(next_layout, "value"))
      |> Phoenix.LiveView.assign(:current_layout_index, next_index)
      |> Phoenix.LiveView.assign(:current_layout_panes, Map.get(next_layout, "panes"))
      |> Phoenix.LiveView.assign(:update_layout_timer, update_layout_timer)
      |> Phoenix.LiveView.assign(:multimedia, multimedia)

    elapsed_time = TimeUtil.get_elapsed_time(start_time)
    Logger.info(":show_next_layout ended successfully (#{elapsed_time})")

    {:noreply, socket}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "arrival_predictions_updated",
          payload: %{},
          topic: "poller"
        },
        socket
      ) do
    Process.send_after(self(), :update_stops_once, 0)
    {:noreply, socket}
  end

  def render(assigns = %{debug: "true"}) do
    ~H"""
    <div style="color: white">
      <Debug prop={{assigns}} />
    </div>
    """
  end

  def render(assigns) do
    theme = "dark"

    case assigns.current_layout_value do
      "landscape_one_pane" ->
        ~H"""
        <div class={{"content-wrapper landscape #{theme}"}}>
          <LandscapeOnePaneLayout prop={{assigns}}/>
        </div>
        """

      "landscape_two_pane_b" ->
        ~H"""
        <div class={{"content-wrapper landscape #{theme}"}}>
          <LandscapeTwoPaneBLayout prop={{assigns}}/>
        </div>
        """

      "landscape_three_pane_a" ->
        ~H"""
        <div class={{"content-wrapper landscape #{theme}"}}>
          <LandscapeThreePaneALayout prop={{assigns}}/>
        </div>
        """

      nil ->
        ~H"""
        <div class={{"content-wrapper landscape #{theme}"}}>
          <div style="font-size: 30px;text-align: center;color: white;margin-top: 50px;">Loading...</div>
        </div>
        """

      unknown_layout ->
        ~H"""
        <unknown_layout class={{"content-wrapper landscape #{theme}"}}>
          <div style="font-size: 30px;text-align: center;color: white;margin-top: 50px;">Layout "{{unknown_layout}}" not implemented</div>
        </unknown_layout>
        """
    end
  end
end
