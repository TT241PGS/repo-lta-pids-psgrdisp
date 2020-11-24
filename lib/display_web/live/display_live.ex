defmodule DisplayWeb.DisplayLive do
  @moduledoc false
  use Phoenix.LiveView
  import Surface
  require Logger
  alias Display.{Buses, Messages}
  alias Display.Utils.{DisplayLiveUtil, TimeUtil}

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
        bus_stop_no: nil,
        bus_stop_name: "",
        panel_id: panel_id,
        previous_layout_value: nil,
        current_layout_value: nil,
        current_layout_index: nil,
        current_layout_panes: nil,
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
        messages: %{message_map: nil, timeline: nil},
        previous_messages: %{message_map: nil, timeline: nil},
        message_list_index: nil,
        message_timeline_index: nil,
        message: "",
        skip_realtime: assigns["skip_realtime"] || false
      )

    case Process.get(:"$callers") do
      nil -> ""
      callers -> Cachex.put(:display, List.last(callers), assigns["scheduled_date_time"])
    end

    if connected?(socket), do: DisplayWeb.Endpoint.subscribe("poller")

    Process.send_after(self(), :update_stops_repeatedly, 0)
    Process.send_after(self(), :update_messages_repeatedly, 0)
    Process.send_after(self(), :update_layout_repeatedly, 0)
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

    case socket.assigns.skip_realtime do
      "true" ->
        DisplayLiveUtil.show_scheduled_predictions(socket, bus_stop_no, start_time, false)

      _ ->
        DisplayLiveUtil.get_realtime_or_scheduled_predictions(
          socket,
          bus_stop_no,
          bus_stop_name,
          start_time,
          false
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

    case socket.assigns.skip_realtime do
      "true" ->
        DisplayLiveUtil.show_scheduled_predictions(socket, bus_stop_no, start_time, true)

      _ ->
        DisplayLiveUtil.get_realtime_or_scheduled_predictions(
          socket,
          bus_stop_no,
          bus_stop_name,
          start_time,
          true
        )
    end
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

    cond do
      length(predictions_realtime_set_1_column) > 0 ->
        Process.send_after(self(), :update_predictions_slider, @slider_speed * 1000)

      length(predictions_realtime_set_2_column) > 0 ->
        Process.send_after(self(), :update_predictions_slider, @slider_speed * 1000)

      length(predictions_scheduled_set_1_column) > 0 ->
        Process.send_after(self(), :update_predictions_slider, @slider_speed * 1000)

      length(predictions_scheduled_set_2_column) > 0 ->
        Process.send_after(self(), :update_predictions_slider, @slider_speed * 1000)
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
    new_messages = Messages.get_messages(socket.assigns.panel_id)

    IO.inspect(new_messages)

    cycle_time = 10

    sample_pm = [50, 50]

    new_messages =
      new_messages
      |> Enum.with_index()
      |> Enum.map(fn {text, index} ->
        # TODO get it from database
        %{text: text, pm: Enum.at(sample_pm, index)}
      end)

    IO.inspect(new_messages)

    # TODO get it from database

    start_time1 = Timex.now()
    new_messages = Messages.get_message_timings(new_messages, cycle_time)
    elapsed_time1 = TimeUtil.get_elapsed_time(start_time1)
    Logger.info(":get_message_timings ended successfully (#{elapsed_time1})")

    IO.inspect({:cycle_time, cycle_time})
    IO.inspect(new_messages)

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
      message_timeline_index: message_timeline_index
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
          0

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

    IO.inspect({:message_list_index, message_list_index})
    IO.inspect({:message_timeline_index, new_message_timeline_index})
    IO.inspect({:message, message})
    IO.inspect({:next_trigger_at, next_trigger_at})
    IO.inspect({:next_trigger_after, next_trigger_after})

    unless is_nil(next_trigger_at) do
      Process.send_after(self(), :update_messages_timeline, next_trigger_after * 1000)
    end

    socket =
      socket
      |> assign(:message_list_index, message_list_index)
      |> assign(:message_timeline_index, new_message_timeline_index)
      |> assign(:message, message)

    elapsed_time = TimeUtil.get_elapsed_time(start_time)
    Logger.info(":update_messages_timeline ended successfully (#{elapsed_time})")

    {:noreply, socket}
  end

  @doc """
    This calls itself after certain period of time to update layout every n seconds
  """
  def handle_info(:update_layout_repeatedly, socket) do
    start_time = Timex.now()

    Logger.info(":update_layout_repeatedly started")
    templates = DisplayLiveUtil.get_template_details_from_cms(socket.assigns.panel_id)

    messages = socket.assigns.messages

    # If messages are present, show template B
    # If messages are not present, show template A
    elected_template_index = if is_nil(messages.timeline), do: 0, else: 1

    # FOR DEVELOPMENT ONLY, not supposed to be commited
    elected_template_index = 0

    layouts = templates |> Enum.at(elected_template_index) |> Map.get("layouts")

    # FOR DEVELOPMENT ONLY, not supposed to be commited
    layouts = [
      %{
        "chosen" => false,
        "duration" => "10",
        "id" => "landscape_two_pane_b_0",
        "label" => "One-Pane Layout",
        "panes" => %{
          "pane1" => %{
            "config" => %{
              "font" => %{
                "color" => %{"label" => "blue", "value" => "blue"},
                "style" => %{"label" => "sans-serif", "value" => "sans-serif"}
              }
            },
            "type" => %{
              "description" =>
                "Lorem ipsum dolor sit amet, consectetur adipisicing elit. Accusantium hic optio tempora harum placeat itaque a architecto exercitationem atque soluta ducimus, esse, laboriosam adipisci, quam ut! Necessitatibus aperiam architecto quis. ",
              "label" => "Predictions and Points of Interest by Service",
              "value" => "predictions_by_service"
            }
          },
          "pane2" => %{
            "config" => %{
              "font" => %{
                "color" => %{"label" => "blue", "value" => "blue"},
                "style" => %{"label" => "sans-serif", "value" => "sans-serif"}
              }
            },
            "type" => %{
              "description" =>
                "Lorem ipsum dolor sit amet, consectetur adipisicing elit. Accusantium hic optio tempora harum placeat itaque a architecto exercitationem atque soluta ducimus, esse, laboriosam adipisci, quam ut! Necessitatibus aperiam architecto quis. ",
              "label" => "Scheduled and ad-hoc messages",
              "value" => "scheduled_and_ad_hoc_messages"
            }
          }
        },
        "selected" => false,
        "value" => "landscape_two_pane_b"
      }
    ]

    is_multi_layout = if length(layouts) > 1, do: true, else: false

    socket = assign(socket, :is_multi_layout, is_multi_layout)

    case socket.assigns.current_layout_index do
      nil ->
        next_layout = Enum.at(layouts, 0)
        next_duration = Map.get(next_layout, "duration") |> String.to_integer()

        socket =
          assign(socket, :previous_layout_value, socket.assigns.current_layout_value)
          |> assign(:current_layout_value, Map.get(next_layout, "value"))
          |> assign(:current_layout_index, 0)
          |> assign(:current_layout_panes, Map.get(next_layout, "panes"))

        Process.send_after(
          self(),
          :update_layout_repeatedly,
          next_duration * 1000
        )

        elapsed_time = TimeUtil.get_elapsed_time(start_time)
        Logger.info(":update_layout_repeatedly ended successfully (#{elapsed_time})")

        {:noreply, socket}

      current_index ->
        next_index = DisplayLiveUtil.get_next_index(layouts, current_index)
        next_layout = Enum.at(layouts, next_index)
        next_duration = Map.get(next_layout, "duration") |> String.to_integer()

        socket =
          assign(socket, :previous_layout_value, socket.assigns.current_layout_value)
          |> assign(:current_layout_value, Map.get(next_layout, "value"))
          |> assign(:current_layout_index, next_index)
          |> assign(:current_layout_panes, Map.get(next_layout, "panes"))

        Process.send_after(
          self(),
          :update_layout_repeatedly,
          next_duration * 1000
        )

        elapsed_time = TimeUtil.get_elapsed_time(start_time)
        Logger.info(":update_layout_repeatedly ended successfully (#{elapsed_time})")

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
    Process.send_after(self(), :update_stops_once, 0)
    {:noreply, socket}
  end

  def render(assigns) do
    theme = "dark"

    is_multi_layout = assigns.is_multi_layout

    is_layout_changed = assigns.current_layout_value != assigns.previous_layout_value

    case assigns.current_layout_value do
      "landscape_one_pane" ->
        ~H"""
        <div class={{"full-page-wrapper #{theme}", hide: is_layout_changed == true, "multi-layout": is_multi_layout == true}}>
          <LandscapeOnePaneLayout prop={{assigns}}/>
        </div>
        """

      "landscape_two_pane_b" ->
        ~H"""
        <div class={{"full-page-wrapper #{theme}", hide: is_layout_changed == true, "multi-layout": is_multi_layout == true}}>
          <LandscapeTwoPaneBLayout prop={{assigns}}/>
        </div>
        """

      "landscape_three_pane_a" ->
        ~H"""
        <div class={{"full-page-wrapper #{theme}", hide: is_layout_changed == true, "multi-layout": is_multi_layout == true}}>
          <LandscapeThreePaneALayout prop={{assigns}}/>
        </div>
        """

      nil ->
        ~H"""
        <div class={{"full-page-wrapper #{theme}", hide: is_layout_changed == true, "multi-layout": is_multi_layout == true}}>
        <div style="font-size: 30px;text-align: center;color: white;margin-top: 50px;">Loading...</div>
        </div>
        """

      unknown_layout ->
        ~H"""
        <div class={{"full-page-wrapper #{theme}", hide: is_layout_changed == true, "multi-layout": is_multi_layout == true}}>
        <div style="font-size: 30px;text-align: center;color: white;margin-top: 50px;">Layout "{{unknown_layout}}" not implemented</div>
        </div>
        """
    end
  end
end
