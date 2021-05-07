defmodule Display.Utils.DisplayLiveUtil do
  @moduledoc false

  require Logger

  alias Display.{Buses, Messages, Poi, RealTime, Scheduled, Templates}
  alias Display.Utils.{TimeUtil, NaturalSort}
  alias DisplayWeb.DisplayLive.Utils

  def incoming_bus_reducer(service, acc, next_bus) do
    next_bus_time =
      if get_in(service, [next_bus, "EstimatedArrival"]) in [nil, ""],
        do: nil,
        else: get_in(service, [next_bus, "EstimatedArrival"])

    case next_bus_time do
      nil ->
        acc

      time ->
        acc ++
          [%{"service_no" => service["ServiceNo"], "time" => TimeUtil.get_eta_in_minutes(time)}]
    end
  end

  def get_incoming_buses(_cached_predictions, %{
        global_message: global_message
      })
      when is_bitstring(global_message) do
    []
  end

  def get_incoming_buses(cached_predictions, %{
        service_message_map: service_message_map,
        hide_services: hide_services
      }) do
    suppress_services = Map.keys(service_message_map) ++ hide_services

    incoming_buses_reducer_1 =
      cached_predictions
      |> Enum.reduce([], &incoming_bus_reducer(&1, &2, "NextBus"))

    incoming_buses_reducer_2 =
      cached_predictions
      |> Enum.reduce([], &incoming_bus_reducer(&1, &2, "NextBus2"))

    (incoming_buses_reducer_1 ++ incoming_buses_reducer_2)
    |> Enum.filter(&(&1["service_no"] not in suppress_services))
    |> Enum.sort_by(&{&1["time"], &1["service_no"]})
    |> Enum.take(5)
    |> Enum.map(fn service ->
      update_in(service, ["time"], &TimeUtil.format_min_to_eta_mins(&1))
    end)
  end

  def get_realtime_or_scheduled_predictions(
        socket,
        bus_stop_no,
        bus_stop_name,
        start_time,
        is_trigger_next,
        is_prediction_next_slide_scheduled
      ) do
    last_bus_map = Buses.get_last_buses_map(bus_stop_no)

    # end of service for the day - show no more messages
    last_bus_in_seconds =
      Enum.map(last_bus_map, fn {_, v} -> v["time_seconds"] end)
      |> Enum.sort()
      |> List.last()

    # handling message when there are no more buses (time after the last bus)
    current_in_seconds = TimeUtil.now_in_seconds()
    end_of_operating_day = current_in_seconds > last_bus_in_seconds

    socket = Phoenix.LiveView.assign(socket, :end_of_operating_day, end_of_operating_day)

    case RealTime.get_predictions_cached(bus_stop_no) do
      {:ok, cached_predictions} ->
        # Used to determine direction from destination code
        service_direction_map = Buses.get_service_direction_map(bus_stop_no)
        suppressed_messages = Messages.get_suppressed_messages(bus_stop_no)

        cached_predictions =
          filter_panel_groups(cached_predictions, socket.assigns.panel_id)
          |> RealTime.set_last_bus(last_bus_map)
          |> Enum.map(fn service ->
            service
            |> add_realtime_direction(service_direction_map)
          end)

        # For QWT
        service_arrival_map =
          cached_predictions
          |> Enum.reduce(%{}, fn service, acc ->
            visit_no =
              case get_in(service, ["NextBus", "VisitNumber"]) do
                nil -> nil
                value -> String.to_integer(value)
              end

            direction = get_in(service, ["NextBus", "Direction"])

            next_bus_1_eta = service["NextBus"]["EstimatedArrival"]

            next_bus_2_eta = get_in(service, ["NextBus2", "EstimatedArrival"])

            value =
              if is_bitstring(next_bus_2_eta) && String.length(next_bus_2_eta) > 0,
                do: [next_bus_1_eta, next_bus_2_eta],
                else: [next_bus_1_eta]

            Map.put(
              acc,
              {service["ServiceNo"], direction, visit_no},
              value
            )
          end)

        %{predictions_current: predictions_previous} = socket.assigns

        quickest_way_to_candidates =
          RealTime.get_quickest_way_to_candidates(
            bus_stop_no,
            service_arrival_map,
            suppressed_messages
          )

        quickest_way_to =
          quickest_way_to_candidates
          |> RealTime.determine_quickest_way_to(bus_stop_no)

        incoming_buses = get_incoming_buses(cached_predictions, suppressed_messages)

        cached_predictions =
          update_cached_predictions(cached_predictions, bus_stop_no)
          |> sort_predictions_by_service_no_asc

        is_bus_interchange =
          Enum.reduce_while(cached_predictions, false, fn x, acc ->
            case get_in(x, ["NextBus", "BerthLabel"]) |> is_bitstring do
              true -> {:halt, true}
              _ -> {:cont, acc}
            end
          end)

        # For debug mode
        waypoints =
          cached_predictions
          |> Enum.map(fn service ->
            service_no = service["ServiceNo"]

            destination = get_in(service, ["NextBus", "Destination"])

            waypoints =
              get_in(service, ["NextBus", "WayPoints"]) ||
                []
                |> Enum.map(fn waypoint -> waypoint["text"] end)
                |> Enum.take(2)
                |> Enum.join(", ")

            {service_no, destination, waypoints}
          end)

        socket =
          socket
          |> Phoenix.LiveView.assign(:is_bus_interchange, is_bus_interchange)
          |> Phoenix.LiveView.assign(:predictions_scheduled_set_1_column, [])
          |> Phoenix.LiveView.assign(:predictions_scheduled_set_2_column, [])
          |> Phoenix.LiveView.assign(:predictions_scheduled_set_1_column_index, nil)
          |> Phoenix.LiveView.assign(:predictions_scheduled_set_2_column_index, nil)
          |> Phoenix.LiveView.assign(
            :predictions_realtime_set_1_column,
            create_predictions_set_1_column(cached_predictions)
          )
          |> Phoenix.LiveView.assign(
            :predictions_realtime_set_2_column,
            create_predictions_set_2_column(cached_predictions)
          )
          |> Phoenix.LiveView.assign(:predictions_scheduled_5_per_page, [])
          |> Phoenix.LiveView.assign(:predictions_scheduled_6_per_page, [])
          |> Phoenix.LiveView.assign(:predictions_scheduled_7_per_page, [])
          |> Phoenix.LiveView.assign(:predictions_scheduled_9_per_page, [])
          |> Phoenix.LiveView.assign(:predictions_scheduled_10_per_page, [])
          |> Phoenix.LiveView.assign(:predictions_scheduled_12_per_page, [])
          |> Phoenix.LiveView.assign(:predictions_scheduled_14_per_page, [])
          |> Phoenix.LiveView.assign(:predictions_scheduled_5_per_page_index, nil)
          |> Phoenix.LiveView.assign(:predictions_scheduled_6_per_page_index, nil)
          |> Phoenix.LiveView.assign(:predictions_scheduled_7_per_page_index, nil)
          |> Phoenix.LiveView.assign(:predictions_scheduled_9_per_page_index, nil)
          |> Phoenix.LiveView.assign(:predictions_scheduled_10_per_page_index, nil)
          |> Phoenix.LiveView.assign(:predictions_scheduled_12_per_page_index, nil)
          |> Phoenix.LiveView.assign(:predictions_scheduled_14_per_page_index, nil)
          |> Phoenix.LiveView.assign(
            :predictions_realtime_5_per_page,
            create_predictions_5_per_page(cached_predictions)
          )
          |> Phoenix.LiveView.assign(
            :predictions_realtime_6_per_page,
            create_predictions_6_per_page(cached_predictions)
          )
          |> Phoenix.LiveView.assign(
            :predictions_realtime_7_per_page,
            create_predictions_7_per_page(cached_predictions)
          )
          |> Phoenix.LiveView.assign(
            :predictions_realtime_9_per_page,
            create_predictions_9_per_page(cached_predictions)
          )
          |> Phoenix.LiveView.assign(
            :predictions_realtime_10_per_page,
            create_predictions_10_per_page(cached_predictions)
          )
          |> Phoenix.LiveView.assign(
            :predictions_realtime_12_per_page,
            create_predictions_12_per_page(cached_predictions)
          )
          |> Phoenix.LiveView.assign(
            :predictions_realtime_14_per_page,
            create_predictions_14_per_page(cached_predictions)
          )
          |> Phoenix.LiveView.assign(
            :incoming_buses,
            incoming_buses
          )
          |> Phoenix.LiveView.assign(
            :predictions_previous,
            predictions_previous
          )
          |> Phoenix.LiveView.assign(
            :predictions_current,
            cached_predictions
          )
          |> Phoenix.LiveView.assign(
            :suppressed_messages,
            suppressed_messages
          )
          |> Phoenix.LiveView.assign(
            :quickest_way_to_candidates,
            quickest_way_to_candidates
          )
          |> Phoenix.LiveView.assign(
            :quickest_way_to,
            quickest_way_to
          )
          |> Phoenix.LiveView.assign(
            :waypoints,
            waypoints
          )

        trigger_next_update_stops(is_trigger_next)

        trigger_prediction_slider(
          predictions_previous,
          cached_predictions,
          is_prediction_next_slide_scheduled
        )

        elapsed_time = TimeUtil.get_elapsed_time(start_time)
        Logger.info(":update_stops ended successfully (#{elapsed_time})")
        {:noreply, socket}

      {:error, :not_found} ->
        Logger.error(
          "Cached_predictions :not_found for bus stop: #{inspect({bus_stop_no, bus_stop_name})}"
        )

        socket = show_blank_screen(socket)

        trigger_next_update_stops(is_trigger_next)
        elapsed_time = TimeUtil.get_elapsed_time(start_time)
        Logger.info(":update_stops ended (#{elapsed_time})")
        {:noreply, socket}

      {:error, error} ->
        Logger.error(
          "Error fetching cached_predictions for bus stop: #{
            inspect({bus_stop_no, bus_stop_name})
          } -> #{inspect(error)}"
        )

        socket = show_blank_screen(socket)

        trigger_next_update_stops(is_trigger_next)
        elapsed_time = TimeUtil.get_elapsed_time(start_time)
        Logger.info(":update_stops failed (#{elapsed_time})")
        {:noreply, socket}
    end
  end

  def show_blank_screen(socket) do
    socket =
      socket
      |> Phoenix.LiveView.assign(:is_bus_interchange, false)
      |> Phoenix.LiveView.assign(:predictions_scheduled_set_1_column, [])
      |> Phoenix.LiveView.assign(:predictions_scheduled_set_2_column, [])
      |> Phoenix.LiveView.assign(:predictions_scheduled_set_1_column_index, nil)
      |> Phoenix.LiveView.assign(:predictions_scheduled_set_2_column_index, nil)
      |> Phoenix.LiveView.assign(
        :predictions_realtime_set_1_column,
        []
      )
      |> Phoenix.LiveView.assign(
        :predictions_realtime_set_2_column,
        []
      )
      |> Phoenix.LiveView.assign(:predictions_scheduled_5_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_scheduled_6_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_scheduled_7_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_scheduled_9_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_scheduled_10_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_scheduled_12_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_scheduled_14_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_scheduled_5_per_page_index, nil)
      |> Phoenix.LiveView.assign(:predictions_scheduled_6_per_page_index, nil)
      |> Phoenix.LiveView.assign(:predictions_scheduled_7_per_page_index, nil)
      |> Phoenix.LiveView.assign(:predictions_scheduled_9_per_page_index, nil)
      |> Phoenix.LiveView.assign(:predictions_scheduled_10_per_page_index, nil)
      |> Phoenix.LiveView.assign(:predictions_scheduled_12_per_page_index, nil)
      |> Phoenix.LiveView.assign(:predictions_scheduled_14_per_page_index, nil)
      |> Phoenix.LiveView.assign(
        :predictions_realtime_5_per_page,
        []
      )
      |> Phoenix.LiveView.assign(
        :predictions_realtime_6_per_page,
        []
      )
      |> Phoenix.LiveView.assign(
        :predictions_realtime_7_per_page,
        []
      )
      |> Phoenix.LiveView.assign(
        :predictions_realtime_9_per_page,
        []
      )
      |> Phoenix.LiveView.assign(
        :predictions_realtime_10_per_page,
        []
      )
      |> Phoenix.LiveView.assign(
        :predictions_realtime_12_per_page,
        []
      )
      |> Phoenix.LiveView.assign(
        :predictions_realtime_14_per_page,
        []
      )
      |> Phoenix.LiveView.assign(
        :incoming_buses,
        []
      )
      |> Phoenix.LiveView.assign(
        :predictions_previous,
        []
      )
      |> Phoenix.LiveView.assign(
        :predictions_current,
        []
      )
      |> Phoenix.LiveView.assign(
        :suppressed_messages,
        %{}
      )
      |> Phoenix.LiveView.assign(
        :quickest_way_to,
        []
      )

    socket
  end

  # This is not used as sheduled predictions are not shown
  def show_scheduled_predictions(
        socket,
        bus_stop_no,
        start_time,
        is_trigger_next,
        is_prediction_next_slide_scheduled
      ) do
    %{predictions_current: predictions_previous} = socket.assigns

    scheduled_predictions =
      Scheduled.get_predictions(bus_stop_no)
      |> filter_panel_groups(socket.assigns.panel_id)

    suppressed_messages = Messages.get_suppressed_messages(bus_stop_no)

    incoming_buses =
      scheduled_predictions
      |> Enum.map(fn prediction -> prediction["ServiceNo"] end)
      |> Scheduled.get_incoming_buses(bus_stop_no, suppressed_messages)

    scheduled_predictions =
      update_scheduled_predictions(scheduled_predictions)
      |> sort_predictions_by_service_no_asc

    is_bus_interchange =
      Enum.reduce_while(scheduled_predictions, false, fn x, acc ->
        case get_in(x, ["NextBus", "BerthLabel"]) |> is_bitstring do
          true -> {:halt, true}
          _ -> {:cont, acc}
        end
      end)

    quickest_way_to = Scheduled.get_quickest_way_to(bus_stop_no, suppressed_messages)

    socket =
      socket
      |> Phoenix.LiveView.assign(:is_bus_interchange, is_bus_interchange)
      |> Phoenix.LiveView.assign(:predictions_realtime_set_1_column, [])
      |> Phoenix.LiveView.assign(:predictions_realtime_set_2_column, [])
      |> Phoenix.LiveView.assign(:predictions_realtime_set_1_column_index, nil)
      |> Phoenix.LiveView.assign(:predictions_realtime_set_2_column_index, nil)
      |> Phoenix.LiveView.assign(
        :predictions_scheduled_set_1_column,
        create_predictions_set_1_column(scheduled_predictions)
      )
      |> Phoenix.LiveView.assign(
        :predictions_scheduled_set_2_column,
        create_predictions_set_2_column(scheduled_predictions)
      )
      |> Phoenix.LiveView.assign(:predictions_realtime_5_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_realtime_6_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_realtime_7_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_realtime_9_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_realtime_10_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_realtime_12_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_realtime_14_per_page, [])
      |> Phoenix.LiveView.assign(:predictions_realtime_5_per_page_index, nil)
      |> Phoenix.LiveView.assign(:predictions_realtime_6_per_page_index, nil)
      |> Phoenix.LiveView.assign(:predictions_realtime_7_per_page_index, nil)
      |> Phoenix.LiveView.assign(:predictions_realtime_9_per_page_index, nil)
      |> Phoenix.LiveView.assign(:predictions_realtime_10_per_page_index, nil)
      |> Phoenix.LiveView.assign(:predictions_realtime_12_per_page_index, nil)
      |> Phoenix.LiveView.assign(:predictions_realtime_14_per_page_index, nil)
      |> Phoenix.LiveView.assign(
        :predictions_scheduled_5_per_page,
        create_predictions_5_per_page(scheduled_predictions)
      )
      |> Phoenix.LiveView.assign(
        :predictions_scheduled_6_per_page,
        create_predictions_6_per_page(scheduled_predictions)
      )
      |> Phoenix.LiveView.assign(
        :predictions_scheduled_7_per_page,
        create_predictions_7_per_page(scheduled_predictions)
      )
      |> Phoenix.LiveView.assign(
        :predictions_scheduled_9_per_page,
        create_predictions_9_per_page(scheduled_predictions)
      )
      |> Phoenix.LiveView.assign(
        :predictions_scheduled_10_per_page,
        create_predictions_10_per_page(scheduled_predictions)
      )
      |> Phoenix.LiveView.assign(
        :predictions_scheduled_12_per_page,
        create_predictions_12_per_page(scheduled_predictions)
      )
      |> Phoenix.LiveView.assign(
        :predictions_scheduled_14_per_page,
        create_predictions_14_per_page(scheduled_predictions)
      )
      |> Phoenix.LiveView.assign(
        :incoming_buses,
        incoming_buses
      )
      |> Phoenix.LiveView.assign(
        :predictions_previous,
        predictions_previous
      )
      |> Phoenix.LiveView.assign(
        :predictions_current,
        scheduled_predictions
      )
      |> Phoenix.LiveView.assign(
        :suppressed_messages,
        suppressed_messages
      )
      |> Phoenix.LiveView.assign(
        :quickest_way_to,
        []
      )

    trigger_next_update_stops(is_trigger_next)

    trigger_prediction_slider(
      predictions_previous,
      scheduled_predictions,
      is_prediction_next_slide_scheduled
    )

    elapsed_time = TimeUtil.get_elapsed_time(start_time)
    Logger.info(":update_stops failed (#{elapsed_time})")
    {:noreply, socket}
  end

  def trigger_next_update_stops(is_trigger) do
    if is_trigger == true do
      Process.send_after(self(), :update_stops_repeatedly, 30_000)
    end
  end

  defp trigger_prediction_slider(
         predictions_previous,
         predictions_current,
         is_prediction_next_slide_scheduled
       ) do
    cond do
      is_prediction_next_slide_scheduled == true ->
        nil

      predictions_previous != predictions_current ->
        Process.send_after(self(), :update_predictions_slider, 100)

      predictions_previous == [] and predictions_current == [] ->
        Process.send_after(self(), :update_predictions_slider, 100)

      true ->
        nil
    end
  end

  def get_template_details_from_cms(panel_id) do
    Templates.list_templates_by_panel_id(panel_id)
    |> Enum.map(fn template ->
      template
      |> get_in([:template_detail])
      |> Jason.decode!()
    end)
  end

  def get_template_details_from_cms_by_template_assign_workflow_id(template_assign_workflow_id) do
    Templates.get_template_detail_by_workflow_id(template_assign_workflow_id)
    |> Enum.map(fn template ->
      template
      |> get_in([:template_detail])
      |> Jason.decode!()
    end)
  end

  def create_predictions_set_1_column(cached_predictions) do
    create_predictions_columnwise(cached_predictions, 1)
  end

  def create_predictions_set_2_column(cached_predictions) do
    create_predictions_columnwise(cached_predictions, 2)
  end

  defp create_predictions_columnwise(cached_predictions, columns) do
    max_rows = 5

    cached_predictions =
      cached_predictions
      |> Enum.with_index()
      |> Enum.reduce([], fn {prediction, index}, acc ->
        remainder = rem(index, max_rows)
        quotient = div(index, max_rows)

        if remainder == 0,
          do: List.insert_at(acc, quotient, [prediction]),
          else: List.update_at(acc, quotient, &(&1 ++ [prediction]))
      end)

    if columns == 2, do: Enum.chunk_every(cached_predictions, 2), else: cached_predictions
  end

  def create_predictions_5_per_page(cached_predictions) do
    create_predictions_rowwise(cached_predictions, 5)
  end

  def create_predictions_6_per_page(cached_predictions) do
    create_predictions_rowwise(cached_predictions, 6)
  end

  def create_predictions_7_per_page(cached_predictions) do
    create_predictions_rowwise(cached_predictions, 7)
  end

  def create_predictions_9_per_page(cached_predictions) do
    create_predictions_rowwise(cached_predictions, 9)
  end

  def create_predictions_10_per_page(cached_predictions) do
    create_predictions_rowwise(cached_predictions, 10)
  end

  def create_predictions_12_per_page(cached_predictions) do
    create_predictions_rowwise(cached_predictions, 12)
  end

  def create_predictions_14_per_page(cached_predictions) do
    create_predictions_rowwise(cached_predictions, 14)
  end

  defp create_predictions_rowwise(cached_predictions, max_rows) do
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

  def update_estimated_arrival(service, next_bus) do
    case Access.get(service, next_bus) do
      nil ->
        service

      _ ->
        update_in(service, [next_bus, "EstimatedArrival"], &TimeUtil.format_time_to_eta_mins(&1))
    end
  end

  def update_scheduled_arrival(prediction) do
    next_buses =
      prediction["NextBuses"]
      |> Enum.with_index()
      |> Enum.map(fn {next_bus, index} ->
        next_bus
        |> update_in(["EstimatedArrival"], &TimeUtil.format_iso_date_to_hh_mm(&1))
        |> Map.put("Order", index + 1)
      end)

    Map.replace!(prediction, "NextBuses", next_buses)
  end

  def update_realtime_destination(
        service,
        bus_stop_map,
        destination_pictogram_map,
        bus_interchange_map,
        bus_hub_map,
        waypoints_map,
        sequence_no_map
      ) do
    case Access.get(service, "NextBus") do
      nil ->
        service

      _ ->
        service
        |> update_realtime_destination_bus_stop(
          bus_stop_map,
          destination_pictogram_map,
          waypoints_map,
          sequence_no_map
        )
        |> update_realtime_destination_bus_interchange(bus_interchange_map)
        |> update_realtime_destination_bus_hub(bus_hub_map)
    end
  end

  defp update_realtime_destination_bus_stop(
         service,
         bus_stop_map,
         destination_pictogram_map,
         waypoints_map,
         sequence_no_map
       ) do
    dest_code =
      case get_in(service, ["NextBus", "DestinationCode"]) do
        nil -> nil
        value -> String.to_integer(value)
      end

    origin_code =
      case get_in(service, ["NextBus", "OriginCode"]) do
        nil -> nil
        value -> String.to_integer(value)
      end

    direction = get_in(service, ["NextBus", "Direction"])
    visit_no = get_in(service, ["NextBus", "VisitNumber"])

    service
    |> update_in(
      ["NextBus", "DestinationPictograms"],
      fn _ ->
        get_in(destination_pictogram_map, [dest_code]) || []
      end
    )
    |> put_in(
      ["NextBus", "Destination"],
      Buses.get_bus_stop_name_from_bus_stop_map(
        bus_stop_map,
        Utils.swap_dest_code_dest_name(dest_code)
      )
    )
    |> put_in(
      ["NextBus", "WayPoints"],
      Poi.get_waypoint_from_waypoint_map(
        waypoints_map,
        sequence_no_map,
        service["ServiceNo"],
        direction,
        visit_no,
        origin_code,
        dest_code
      )
    )
  end

  defp update_realtime_destination_bus_interchange(
         service,
         bus_interchange_map
       ) do
    bus_interchange_key = service["ServiceNo"]

    case Map.get(
           bus_interchange_map,
           bus_interchange_key
         ) do
      nil ->
        service

      bus_interchange ->
        service
        |> update_in(
          ["NextBus", "Destination"],
          fn prev ->
            if is_nil(bus_interchange["destination"]),
              do: prev,
              else: bus_interchange["destination"]
          end
        )
        |> update_in(
          ["NextBus", "DestinationPictograms"],
          fn prev ->
            if is_nil(bus_interchange["destination"]),
              do: prev,
              else: []
          end
        )
        |> update_in(
          ["NextBus", "BerthLabel"],
          fn prev ->
            if is_nil(bus_interchange["berth_label"]),
              do: prev,
              else: bus_interchange["berth_label"]
          end
        )
        |> update_in(
          ["NextBus", "WayPoints"],
          fn prev ->
            if is_nil(bus_interchange["way_points"]),
              do: prev,
              else: bus_interchange["way_points"]
          end
        )
    end
  end

  defp update_realtime_destination_bus_hub(
         service,
         bus_hub_map
       ) do
    direction = get_in(service, ["NextBus", "Direction"])

    visit_no =
      case get_in(service, ["NextBus", "VisitNumber"]) do
        nil -> nil
        value -> String.to_integer(value)
      end

    bus_hub =
      Map.take(
        bus_hub_map,
        [
          {service["ServiceNo"], direction, nil},
          {service["ServiceNo"], direction, visit_no}
        ]
      )

    cond do
      bus_hub == %{} ->
        service

      true ->
        bus_hub = Map.to_list(bus_hub) |> List.first() |> elem(1)

        service
        |> update_in(
          ["NextBus", "Destination"],
          fn prev ->
            if is_nil(bus_hub["destination"]),
              do: prev,
              else: bus_hub["destination"]
          end
        )
        |> update_in(
          ["NextBus", "DestinationPictograms"],
          fn prev ->
            if is_nil(bus_hub["destination"]),
              do: prev,
              else: []
          end
        )
        |> update_in(
          ["NextBus", "WayPoints"],
          fn prev ->
            if is_nil(bus_hub["way_points"]),
              do: prev,
              else: bus_hub["way_points"]
          end
        )
    end
  end

  defp add_realtime_direction(service, service_direction_map) do
    case get_in(service, ["NextBus", "DestinationCode"]) do
      nil ->
        nil

      dest_code ->
        dest_code =
          dest_code
          |> String.to_integer()

        value =
          Map.take(
            service_direction_map,
            [
              {service["ServiceNo"], dest_code},
              {service["ServiceNo"], Utils.swap_dest_code_direction(dest_code)}
            ]
          )

        direction =
          cond do
            value == %{} ->
              nil

            true ->
              Map.to_list(value) |> List.first() |> elem(1)
          end

        service
        |> put_in(
          ["NextBus", "Direction"],
          direction
        )
    end
  end

  def update_realtime_no_of_stops(service, no_of_stops_map) do
    no_of_stops =
      Buses.get_no_of_stops_from_map_by_dpi_route_code_and_dest_code(
        no_of_stops_map,
        {service["ServiceNo"], service["NextBus"]["DestinationCode"] |> String.to_integer()}
      )

    Map.put(service, "NoOfStops", no_of_stops)
  end

  def update_scheduled_destination(service, bus_stop_map, destination_pictogram_map) do
    case Access.get(service, "DestinationCode") do
      nil ->
        service

      _ ->
        update_in(
          service,
          ["DestinationPictograms"],
          fn _ ->
            dest_code = get_in(service, ["DestinationCode"])
            get_in(destination_pictogram_map, [dest_code]) || []
          end
        )
        |> update_in(
          ["DestinationCode"],
          &Buses.get_bus_stop_name_from_bus_stop_map(
            bus_stop_map,
            Utils.swap_dest_code_dest_name(&1)
          )
        )
    end
  end

  def update_cached_predictions(cached_predictions, bus_stop_no) do
    cached_predictions =
      cached_predictions
      |> Flow.from_enumerable()
      |> Flow.map(fn service ->
        service
        |> update_estimated_arrival("NextBus")
        |> update_estimated_arrival("NextBus2")
        |> update_estimated_arrival("NextBus3")
      end)

    dest_codes =
      cached_predictions
      |> Enum.map(fn service ->
        service
        |> get_in(["NextBus", "DestinationCode"])
      end)

    bus_stop_map = Buses.get_bus_stop_map_by_nos(dest_codes)
    bus_interchange_map = Buses.get_bus_interchange_service_mapping_by_no(bus_stop_no)
    bus_hub_map = Buses.get_bus_hub_service_mapping_by_no(bus_stop_no)
    waypoints_map = Poi.get_waypoints_map(bus_stop_no)
    # To get visit_no based on sequence no because waypoint map dont have visit_no
    sequence_no_map = Buses.get_sequence_no_map(bus_stop_no)

    destination_pictogram_map =
      dest_codes
      |> Poi.get_many_destinations_pictogram()

    cached_predictions =
      cached_predictions
      |> Enum.map(fn service ->
        service
        |> update_realtime_destination(
          bus_stop_map,
          destination_pictogram_map,
          bus_interchange_map,
          bus_hub_map,
          waypoints_map,
          sequence_no_map
        )
      end)

    cached_predictions
  end

  def update_scheduled_predictions(scheduled_predictions) do
    scheduled_predictions =
      scheduled_predictions
      |> Flow.from_enumerable()
      |> Flow.map(fn prediction ->
        update_scheduled_arrival(prediction)
      end)

    dest_codes =
      scheduled_predictions
      |> Enum.map(fn service ->
        service
        |> get_in(["DestinationCode"])
      end)

    bus_stop_map =
      dest_codes
      |> Buses.get_bus_stop_map_by_nos()

    destination_pictogram_map =
      dest_codes
      |> Poi.get_many_destinations_pictogram()

    scheduled_predictions
    |> Enum.map(fn service ->
      service
      |> update_scheduled_destination(bus_stop_map, destination_pictogram_map)
    end)
  end

  def get_next_index(layouts, current_index) do
    max_index = length(layouts) - 1

    cond do
      current_index < max_index -> current_index + 1
      current_index == max_index -> 0
      true -> 0
    end
  end

  def update_layout(socket, layouts, current_layout_index) do
    %{current_layouts: current_layouts} = socket.assigns

    cond do
      not is_nil(layouts) and layouts == current_layouts ->
        {:noreply, socket}

      true ->
        next_index =
          case current_layout_index do
            nil ->
              0

            current_index ->
              get_next_index(layouts, current_index)
          end

        next_layout = Enum.at(layouts, next_index)
        next_duration = Map.get(next_layout, "duration") |> String.to_integer()

        update_layout_prev_timer = socket.assigns.update_layout_timer

        multimedia = get_multimedia(next_layout)

        socket = reset_image_sequence_slider_maybe(multimedia, socket)

        case update_layout_prev_timer do
          nil ->
            nil

          timer_ref ->
            Process.cancel_timer(timer_ref)
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
          |> Phoenix.LiveView.assign(:current_layouts, layouts)
          |> Phoenix.LiveView.assign(:current_layout_value, Map.get(next_layout, "value"))
          |> Phoenix.LiveView.assign(:current_layout_index, next_index)
          |> Phoenix.LiveView.assign(:current_layout_panes, Map.get(next_layout, "panes"))
          |> Phoenix.LiveView.assign(:update_layout_timer, update_layout_timer)
          |> Phoenix.LiveView.assign(:multimedia, multimedia)

        {:noreply, socket}
    end
  end

  defp filter_panel_groups(predictions, panel_id) do
    with config <- Buses.get_panel_configuration_by_panel_id(panel_id),
         false <- is_nil(config) do
      %{
        service_group_type: group_type,
        day_group: day_group,
        night_group: night_group,
        service_group: service_group
      } = config

      cond do
        group_type == "SERVICE_GROUP" ->
          filter_groups(service_group, predictions)

        group_type == "DAY_NIGHT_GROUP" and TimeUtil.is_day_now() ->
          filter_groups(day_group, predictions)

        group_type == "DAY_NIGHT_GROUP" and not TimeUtil.is_day_now() ->
          filter_groups(night_group, predictions)

        true ->
          predictions
      end
    else
      _ -> predictions
    end
  end

  def get_cycle_time_from_layouts(nil) do
    300
  end

  def get_cycle_time_from_layouts(message_layouts) do
    message_layouts
    |> Enum.reduce(nil, fn layout, acc ->
      cycle_time =
        get_in(layout, ["panes", "pane1", "config", "cycle_time"]) ||
          get_in(layout, ["panes", "pane2", "config", "cycle_time"]) ||
          get_in(layout, ["panes", "pane3", "config", "cycle_time"])

      case cycle_time do
        nil -> acc
        cycle_time -> cycle_time |> String.to_integer()
      end
    end)
  end

  def get_cycle_time_from_templates(nil), do: nil
  def get_cycle_time_from_templates([]), do: nil

  def get_cycle_time_from_templates(templates) do
    case Enum.at(templates, 1) do
      nil ->
        nil

      %{"layouts" => message_layouts} ->
        message_layouts
        |> Enum.reduce_while(nil, fn
          layout, acc ->
            cycle_time =
              get_in(layout, ["panes", "pane1", "config", "cycle_time"]) ||
                get_in(layout, ["panes", "pane2", "config", "cycle_time"]) ||
                get_in(layout, ["panes", "pane3", "config", "cycle_time"])

            if is_nil(cycle_time),
              do: {:cont, acc},
              else: {:halt, String.to_integer(cycle_time)}
        end)

      _ ->
        nil
    end
  end

  def get_multimedia(nil) do
    nil
  end

  def get_multimedia(layout) do
    pane_no =
      ["pane1", "pane2", "pane3"]
      |> Enum.reduce(nil, fn pane_no, acc ->
        case get_in(layout, ["panes", pane_no, "config", "multimediaType", "value"]) do
          nil -> acc
          _ -> pane_no
        end
      end)

    type =
      case is_bitstring(pane_no) do
        true -> get_in(layout, ["panes", pane_no, "config", "multimediaType", "value"])
        false -> nil
      end

    base_url = Application.get_env(:display, :multimedia_base_url)

    content =
      case type do
        nil ->
          nil

        "IMAGE" ->
          resource =
            get_in(layout, ["panes", pane_no, "config", "file", "fileUrl"])
            |> String.split("/")
            |> List.last()

          base_url <> resource

        "VIDEO" ->
          resource =
            get_in(layout, ["panes", pane_no, "config", "video", "fileUrl"])
            |> String.split("/")
            |> List.last()

          base_url <> resource

        "IMAGE SEQUENCE" ->
          get_in(layout, ["panes", pane_no, "config", "files"])
          |> Enum.map(fn file ->
            resource =
              file["image"]["fileUrl"]
              |> String.split("/")
              |> List.last()

            %{
              "url" => base_url <> resource,
              "duration" => file["duration"]
            }
          end)
      end

    %{type: type, content: content}
  end

  def reset_image_sequence_slider_maybe(%{type: "IMAGE SEQUENCE"}, socket) do
    # Clear the previous timer
    # Call live view show_next_image_sequence
    # Reset multimedia_image_sequence_current_index

    case socket.assigns.multimedia_image_sequence_next_trigger_at do
      nil -> nil
      timer_ref -> Process.cancel_timer(timer_ref)
    end

    Process.send_after(self(), :show_next_image_sequence, 1)

    socket
    |> Phoenix.LiveView.assign(:multimedia_image_sequence_current_index, nil)
  end

  def reset_image_sequence_slider_maybe(_multimedia, socket) do
    socket
  end

  defp filter_groups(groups, predictions) when is_bitstring(groups) and is_list(predictions) do
    groups
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reduce([], fn service_no, acc ->
      acc ++ Enum.filter(predictions, fn service -> service["ServiceNo"] == service_no end)
    end)
  end

  defp filter_groups(_groups, predictions) do
    predictions
  end

  def discard_inactive_multimedia_layouts(templates) do
    Enum.map(templates, fn template ->
      update_in(template, ["layouts"], &filter_active_multimedia_layout/1)
    end)
  end

  defp filter_active_multimedia_layout(layouts) do
    layouts
    |> Enum.filter(fn layout ->
      multimedia_pane_no =
        ["pane1", "pane2", "pane3"]
        |> Enum.reduce(nil, fn pane_no, acc ->
          case get_in(layout, ["panes", pane_no, "config", "multimediaType", "value"]) do
            nil -> acc
            _ -> pane_no
          end
        end)

      case is_bitstring(multimedia_pane_no) do
        true ->
          config = get_in(layout, ["panes", multimedia_pane_no, "config"])

          start_date = config["startDate"] |> String.split("T") |> List.first()
          start_time = config["startTime"]

          start_date_time =
            "#{start_date}T#{start_time}:00+08:00" |> Timex.parse!("{ISO:Extended}")

          end_date = config["endDate"] |> String.split("T") |> List.first()
          end_time = config["endTime"]
          end_date_time = "#{end_date}T#{end_time}:00+08:00" |> Timex.parse!("{ISO:Extended}")

          now = TimeUtil.get_time_now()

          if Timex.compare(now, start_date_time) >= 0 and Timex.compare(now, end_date_time) <= 0,
            do: true,
            else: false

        false ->
          true
      end
    end)
  end

  defp sort_predictions_by_service_no_asc(predictions) do
    predictions
    |> Enum.sort_by(
      fn p ->
        NaturalSort.format_item(p["ServiceNo"], false)
      end,
      NaturalSort.sort_direction(:asc)
    )
  end
end
