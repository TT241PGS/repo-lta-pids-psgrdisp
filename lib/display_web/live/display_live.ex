defmodule DisplayWeb.DisplayLive do
  @moduledoc false
  use Phoenix.LiveView
  import Surface
  require Logger
  alias Display.{Buses, Messages}
  alias Display.Utils.{DisplayLiveUtil, TimeUtil}
  # prediction page switching frequency in seconds
  @slider_speed 10

  def mount(
        %{"panel_id" => panel_id} = assigns,
        _session,
        socket
      ) do
    start_time = Timex.now()
    Logger.info("Mount started")

    socket =
      assign(socket,
        end_of_operating_day: false,
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
        layout_mode: nil,
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
        predictions_realtime_5_per_page: [],
        predictions_realtime_6_per_page: [],
        predictions_realtime_7_per_page: [],
        predictions_realtime_9_per_page: [],
        predictions_realtime_10_per_page: [],
        predictions_realtime_11_per_page: [],
        predictions_realtime_12_per_page: [],
        predictions_realtime_14_per_page: [],
        predictions_realtime_5_per_page_index: nil,
        predictions_realtime_6_per_page_index: nil,
        predictions_realtime_7_per_page_index: nil,
        predictions_realtime_9_per_page_index: nil,
        predictions_realtime_10_per_page_index: nil,
        predictions_realtime_11_per_page_index: nil,
        predictions_realtime_12_per_page_index: nil,
        predictions_realtime_14_per_page_index: nil,
        predictions_scheduled_5_per_page: [],
        predictions_scheduled_6_per_page: [],
        predictions_scheduled_7_per_page: [],
        predictions_scheduled_9_per_page: [],
        predictions_scheduled_10_per_page: [],
        predictions_scheduled_11_per_page: [],
        predictions_scheduled_12_per_page: [],
        predictions_scheduled_14_per_page: [],
        predictions_scheduled_5_per_page_index: nil,
        predictions_scheduled_6_per_page_index: nil,
        predictions_scheduled_7_per_page_index: nil,
        predictions_scheduled_9_per_page_index: nil,
        predictions_scheduled_10_per_page_index: nil,
        predictions_scheduled_11_per_page_index: nil,
        predictions_scheduled_12_per_page_index: nil,
        predictions_scheduled_14_per_page_index: nil,
        is_prediction_next_slide_scheduled: false,
        messages: %{message_map: nil, timeline: nil},
        suppressed_messages: %{global_message: nil, service_message_map: %{}, hide_services: []},
        previous_messages: %{message_map: nil, timeline: nil},
        message_list_index: nil,
        message_timeline_index: nil,
        message: %{},
        cycle_time: nil,
        quickest_way_to_candidates: %{},
        quickest_way_to: [],
        is_show_non_message_template: false,
        update_messages_timeline_timer: nil,
        multimedia: %{content: nil, type: nil},
        multimedia_image_sequence_next_trigger_at: nil,
        multimedia_image_sequence_current_index: nil,
        multimedia_image_sequence_current_url: nil,
        waypoints: [],
        zoom: assigns["zoom"] || 0.17,
        preview_workflow: assigns["preview_workflow"] || nil,
        preview_message: assigns["preview_message"] || nil
      )

    case Process.get(:"$callers") do
      nil -> ""
      callers -> Cachex.put(:display, List.last(callers), assigns["scheduled_date_time"])
    end

    if connected?(socket) do
      DisplayWeb.Endpoint.subscribe("poller")
      %{preview_workflow: preview_workflow, preview_message: preview_message} = socket.assigns

      socket =
        cond do
          # Preview template with sample message
          is_bitstring(preview_workflow) and is_bitstring(preview_message) ->
            init_preview_messages(socket, preview_message)

          # Preview template without message
          is_bitstring(preview_workflow) ->
            socket

          # Default functionality
          true ->
            DisplayWeb.Endpoint.subscribe("message:#{panel_id}")

            # Only one instance of each children is created, even if same panel is opened in multiple tabs
            AdvisorySupervisor.start_link(panel_id)
            AdvisorySupervisor.start(panel_id)
            socket
        end

      init_handlers(socket, start_time)
    else
      {:ok, socket}
    end
  end

  def init_preview_messages(socket, preview_message) do
    message = %{
      line: nil,
      pm: 100,
      text: "This is #{preview_message} preview message",
      type: "#{String.upcase(preview_message) |> String.trim()}"
    }

    socket
    |> assign(:message, message)
  end

  def init_handlers(socket, start_time) do
    Process.send_after(self(), :update_stops_repeatedly, 0)
    Process.send_after(self(), {:update_layout_repeatedly, "fetch"}, 0)
    Process.send_after(self(), :update_time_repeatedly, 0)
    elapsed_time = TimeUtil.get_elapsed_time(start_time)
    Logger.info("Mount ended (#{elapsed_time})")
    {:ok, socket}
  end

  def handle_info({ref, _return_value}, socket) do
    Process.demonitor(ref, [:flush])
    {:noreply, socket}
  end

  def handle_info({_, _, _, _, _}, socket) do
    {:noreply, socket}
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

    bus_stop_name = Buses.get_bus_hub_or_stop_name_by_no(bus_stop_no)

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

    bus_stop_name = Buses.get_bus_hub_or_stop_name_by_no(bus_stop_no)

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
      predictions_scheduled_set_2_column_index: predictions_scheduled_set_2_column_index,
      predictions_realtime_5_per_page: predictions_realtime_5_per_page,
      predictions_realtime_6_per_page: predictions_realtime_6_per_page,
      predictions_realtime_7_per_page: predictions_realtime_7_per_page,
      predictions_realtime_9_per_page: predictions_realtime_9_per_page,
      predictions_realtime_10_per_page: predictions_realtime_10_per_page,
      predictions_realtime_11_per_page: predictions_realtime_11_per_page,
      predictions_realtime_12_per_page: predictions_realtime_12_per_page,
      predictions_realtime_14_per_page: predictions_realtime_14_per_page,
      predictions_realtime_5_per_page_index: predictions_realtime_5_per_page_index,
      predictions_realtime_6_per_page_index: predictions_realtime_6_per_page_index,
      predictions_realtime_7_per_page_index: predictions_realtime_7_per_page_index,
      predictions_realtime_9_per_page_index: predictions_realtime_9_per_page_index,
      predictions_realtime_10_per_page_index: predictions_realtime_10_per_page_index,
      predictions_realtime_11_per_page_index: predictions_realtime_11_per_page_index,
      predictions_realtime_12_per_page_index: predictions_realtime_12_per_page_index,
      predictions_realtime_14_per_page_index: predictions_realtime_14_per_page_index,
      predictions_scheduled_5_per_page: predictions_scheduled_5_per_page,
      predictions_scheduled_6_per_page: predictions_scheduled_6_per_page,
      predictions_scheduled_7_per_page: predictions_scheduled_7_per_page,
      predictions_scheduled_9_per_page: predictions_scheduled_9_per_page,
      predictions_scheduled_10_per_page: predictions_scheduled_10_per_page,
      predictions_scheduled_11_per_page: predictions_scheduled_11_per_page,
      predictions_scheduled_12_per_page: predictions_scheduled_12_per_page,
      predictions_scheduled_14_per_page: predictions_scheduled_14_per_page,
      predictions_scheduled_5_per_page_index: predictions_scheduled_5_per_page_index,
      predictions_scheduled_6_per_page_index: predictions_scheduled_6_per_page_index,
      predictions_scheduled_7_per_page_index: predictions_scheduled_7_per_page_index,
      predictions_scheduled_9_per_page_index: predictions_scheduled_9_per_page_index,
      predictions_scheduled_10_per_page_index: predictions_scheduled_10_per_page_index,
      predictions_scheduled_11_per_page_index: predictions_scheduled_11_per_page_index,
      predictions_scheduled_12_per_page_index: predictions_scheduled_12_per_page_index,
      predictions_scheduled_14_per_page_index: predictions_scheduled_14_per_page_index
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

        length(predictions_realtime_5_per_page) > 0 ->
          @slider_speed

        length(predictions_realtime_6_per_page) > 0 ->
          @slider_speed

        length(predictions_realtime_7_per_page) > 0 ->
          @slider_speed

        length(predictions_realtime_9_per_page) > 0 ->
          @slider_speed

        length(predictions_realtime_10_per_page) > 0 ->
          @slider_speed

        length(predictions_realtime_11_per_page) > 0 ->
          @slider_speed

        length(predictions_realtime_12_per_page) > 0 ->
          @slider_speed

        length(predictions_realtime_14_per_page) > 0 ->
          @slider_speed

        length(predictions_scheduled_5_per_page) > 0 ->
          @slider_speed

        length(predictions_scheduled_6_per_page) > 0 ->
          @slider_speed

        length(predictions_scheduled_7_per_page) > 0 ->
          @slider_speed

        length(predictions_scheduled_9_per_page) > 0 ->
          @slider_speed

        length(predictions_scheduled_10_per_page) > 0 ->
          @slider_speed

        length(predictions_scheduled_11_per_page) > 0 ->
          @slider_speed

        length(predictions_scheduled_12_per_page) > 0 ->
          @slider_speed

        length(predictions_scheduled_14_per_page) > 0 ->
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
      |> assign(
        :predictions_realtime_5_per_page_index,
        determine_prediction_next_index(
          predictions_realtime_5_per_page,
          predictions_realtime_5_per_page_index
        )
      )
      |> assign(
        :predictions_realtime_6_per_page_index,
        determine_prediction_next_index(
          predictions_realtime_6_per_page,
          predictions_realtime_6_per_page_index
        )
      )
      |> assign(
        :predictions_realtime_7_per_page_index,
        determine_prediction_next_index(
          predictions_realtime_7_per_page,
          predictions_realtime_7_per_page_index
        )
      )
      |> assign(
        :predictions_realtime_9_per_page_index,
        determine_prediction_next_index(
          predictions_realtime_9_per_page,
          predictions_realtime_9_per_page_index
        )
      )
      |> assign(
        :predictions_realtime_10_per_page_index,
        determine_prediction_next_index(
          predictions_realtime_10_per_page,
          predictions_realtime_10_per_page_index
        )
      )
      |> assign(
        :predictions_realtime_11_per_page_index,
        determine_prediction_next_index(
          predictions_realtime_11_per_page,
          predictions_realtime_11_per_page_index
        )
      )
      |> assign(
        :predictions_realtime_12_per_page_index,
        determine_prediction_next_index(
          predictions_realtime_12_per_page,
          predictions_realtime_12_per_page_index
        )
      )
      |> assign(
        :predictions_realtime_14_per_page_index,
        determine_prediction_next_index(
          predictions_realtime_14_per_page,
          predictions_realtime_14_per_page_index
        )
      )
      |> assign(
        :predictions_scheduled_5_per_page_index,
        determine_prediction_next_index(
          predictions_scheduled_5_per_page,
          predictions_scheduled_5_per_page_index
        )
      )
      |> assign(
        :predictions_scheduled_6_per_page_index,
        determine_prediction_next_index(
          predictions_scheduled_6_per_page,
          predictions_scheduled_6_per_page_index
        )
      )
      |> assign(
        :predictions_scheduled_7_per_page_index,
        determine_prediction_next_index(
          predictions_scheduled_7_per_page,
          predictions_scheduled_7_per_page_index
        )
      )
      |> assign(
        :predictions_scheduled_9_per_page_index,
        determine_prediction_next_index(
          predictions_scheduled_9_per_page,
          predictions_scheduled_9_per_page_index
        )
      )
      |> assign(
        :predictions_scheduled_10_per_page_index,
        determine_prediction_next_index(
          predictions_scheduled_10_per_page,
          predictions_scheduled_10_per_page_index
        )
      )
      |> assign(
        :predictions_scheduled_11_per_page_index,
        determine_prediction_next_index(
          predictions_scheduled_11_per_page,
          predictions_scheduled_11_per_page_index
        )
      )
      |> assign(
        :predictions_scheduled_12_per_page_index,
        determine_prediction_next_index(
          predictions_scheduled_12_per_page,
          predictions_scheduled_12_per_page_index
        )
      )
      |> assign(
        :predictions_scheduled_14_per_page_index,
        determine_prediction_next_index(
          predictions_scheduled_14_per_page,
          predictions_scheduled_14_per_page_index
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

      index >= 0 and index < length(list) - 1 ->
        index + 1

      true ->
        0
    end
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
  def handle_info({:update_layout_repeatedly, type}, socket) do
    start_time = Timex.now()

    Logger.info(":update_layout_repeatedly started")

    %{
      panel_id: panel_id,
      message: message,
      current_layout_index: current_layout_index,
      is_show_non_message_template: is_show_non_message_template,
      preview_workflow: preview_workflow,
      update_layout_timer: update_layout_timer,
      multimedia_image_sequence_next_trigger_at: multimedia_image_sequence_next_trigger_at
    } = socket.assigns

    templates =
      case preview_workflow do
        nil ->
          DisplayLiveUtil.get_template_details_from_cms(panel_id)
          |> DisplayLiveUtil.discard_inactive_multimedia_layouts()

        preview_workflow ->
          DisplayLiveUtil.get_template_details_from_cms_by_template_assign_workflow_id(
            preview_workflow
          )
          |> DisplayLiveUtil.discard_inactive_multimedia_layouts()
      end

    prev_templates = socket.assigns[:templates]

    socket = socket |> assign(:templates, templates)

    layout_mode =
      case length(templates) > 0 do
        true -> List.first(templates) |> get_in(["orientation", "value"])
        _ -> nil
      end

    template_index =
      cond do
        is_show_non_message_template == true ->
          0

        # If messages are not present, show template A
        message == %{} ->
          0

        # If messages are present, show template B
        true ->
          1
      end

    # FOR DEVELOPMENT ONLY, not supposed to be commited
    # template_index = 0

    case type do
      "once" ->
        {layouts, socket} =
          prepare_to_refresh_layout(socket, templates, template_index, panel_id, layout_mode)

        result = DisplayLiveUtil.update_layout(socket, layouts, current_layout_index)

        elapsed_time = TimeUtil.get_elapsed_time(start_time)
        Logger.info(":update_layout_repeatedly ended successfully (#{elapsed_time})")

        result

      "fetch" ->
        case prev_templates == templates do
          true ->
            {:noreply, socket}

          false ->
            {layouts, socket} =
              prepare_to_refresh_layout(socket, templates, template_index, panel_id, layout_mode)

            DisplayLiveUtil.reset_timer(multimedia_image_sequence_next_trigger_at)
            DisplayLiveUtil.reset_timer(update_layout_timer)

            result = DisplayLiveUtil.update_layout(socket, layouts, current_layout_index)

            elapsed_time = TimeUtil.get_elapsed_time(start_time)
            Logger.info(":update_layout_repeatedly ended successfully (#{elapsed_time})")

            result
        end

        schedule_work_update_layout_repeatedly()
    end
  end

  defp prepare_to_refresh_layout(socket, templates, template_index, panel_id, layout_mode) do
    layouts = templates |> Enum.at(template_index) |> Map.get("layouts")

    message_layouts = templates |> Enum.at(1) |> Map.get("layouts")

    cycle_time = DisplayLiveUtil.get_cycle_time_from_layouts(message_layouts)

    GenServer.cast(
      {:via, Registry, {AdvisoryRegistry, "advisory_timeline_generator_#{panel_id}"}},
      {:cycle_time, cycle_time}
    )

    socket =
      socket
      |> assign(:cycle_time, cycle_time)
      |> assign(:layout_mode, layout_mode)

    {layouts, socket}
  end

  defp schedule_work_update_layout_repeatedly() do
    # In 60 seconds
    Process.send_after(self(), {:update_layout_repeatedly, "fetch"}, 60 * 1000)
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
        {:update_layout_repeatedly, "once"},
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

  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "show_message",
          payload: %{message: message, timeline: timeline, message_map: message_map},
          topic: "message:" <> panel_id
        },
        %{assigns: %{panel_id: socket_panel_id}} = socket
      )
      when panel_id == socket_panel_id do
    socket =
      socket
      |> assign(:message, message)
      # For debug
      |> assign(:messages, %{timeline: timeline, message_map: message_map})

    %{templates: templates, current_layout_index: current_layout_index} = socket.assigns
    layouts = templates |> Enum.at(1) |> Map.get("layouts")

    socket
    |> assign(:is_show_non_message_template, false)
    |> DisplayLiveUtil.update_layout(layouts, current_layout_index)
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "show_non_message_template",
          topic: "message:" <> panel_id,
          payload: %{timeline: timeline, message_map: message_map}
        },
        %{assigns: %{panel_id: socket_panel_id}} = socket
      )
      when panel_id == socket_panel_id do
    %{templates: templates, current_layout_index: current_layout_index} = socket.assigns
    layouts = templates |> Enum.at(0) |> Map.get("layouts")

    socket
    |> assign(:is_show_non_message_template, true)
    # For debug
    |> assign(:messages, %{timeline: timeline, message_map: message_map})
    |> DisplayLiveUtil.update_layout(layouts, current_layout_index)
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

    cond do
      # svr and device online + data from datamall
      assigns.predictions_current != [] ->
        case assigns.current_layout_value do
          "landscape_one_pane" ->
            ~H"""
            <div class={{"content-wrapper landscape #{theme}"}}>
              <LandscapeOnePaneLayout prop={{assigns}}/>
            </div>
            """

          "landscape_three_pane" ->
            ~H"""
            <div class={{"content-wrapper landscape #{theme}"}}>
              <LandscapeThreePaneLayout prop={{assigns}}/>
            </div>
            """

          "landscape_four_pane_a" ->
            ~H"""
            <div class={{"content-wrapper landscape #{theme}"}}>
              <LandscapeFourPaneALayout prop={{assigns}}/>
            </div>
            """

          "landscape_four_pane_b" ->
            ~H"""
            <div class={{"content-wrapper landscape #{theme}"}}>
              <LandscapeFourPaneBLayout prop={{assigns}}/>
            </div>
            """

          "portrait_one_pane" ->
            ~H"""
            <div class={{"content-wrapper portrait #{theme}"}}>
              <PortraitOnePaneLayout prop={{assigns}} service_per_page="11"/>
            </div>
            """

          "portrait_two_pane" ->
            ~H"""
            <div class={{"content-wrapper portrait #{theme}"}}>
              <PortraitTwoPaneLayout prop={{assigns}} service_per_page="9"/>
            </div>
            """

          "portrait_three_pane" ->
            ~H"""
            <div class={{"content-wrapper portrait #{theme}"}}>
              <PortraitThreePaneALayout prop={{assigns}} service_per_page="7"/>
            </div>
            """

          "portrait_three_pane_b" ->
            ~H"""
            <div class={{"content-wrapper portrait #{theme}"}}>
              <PortraitThreePaneBLayout prop={{assigns}} service_per_page="5"/>
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

      # when its end of operating day - default is false so it'll be skipped over
      assigns.end_of_operating_day ->
        case assigns.layout_mode do
          "landscape" ->
            ~H"""
            <div class={{"content-wrapper landscape #{theme}"}}>
              <LandscapeNoBusInfoMessage prop={{assigns}}/>
            </div>
            """

          "portrait" ->
            ~H"""
            <div class={{"content-wrapper portrait #{theme}"}}>
              <PortraitNoBusInfoMessage prop={{assigns}}/>
            </div>
            """

          nil ->
            ~H"""
            <div class={{"content-wrapper"}}>
            </div>
            """
        end

      # svr, device online + no data from datamall
      true ->
        case assigns.layout_mode do
          "landscape" ->
            ~H"""
            <div class={{"content-wrapper landscape #{theme}"}}>
              <LandscapeNoBusInfoMessage prop={{assigns}}/>
            </div>
            """

          "portrait" ->
            ~H"""
            <div class={{"content-wrapper portrait #{theme}"}}>
              <PortraitNoBusInfoMessage prop={{assigns}}/>
            </div>
            """

          nil ->
            ~H"""
            <div class={{"content-wrapper"}}>
              <div style="font-size: 30px;text-align: center;color: white;margin-top: 50px;">Loading...</div>
            </div>
            """
        end
    end
  end
end
