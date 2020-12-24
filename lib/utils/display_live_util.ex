defmodule Display.Utils.DisplayLiveUtil do
  @moduledoc false

  require Logger

  alias Display.{Buses, RealTime, Scheduled, Templates}
  alias Display.Utils.{NaturalSort, TimeUtil}

  def incoming_bus_reducer(service, acc) do
    next_bus_time =
      if service["NextBus"]["EstimatedArrival"] == "",
        do: nil,
        else: service["NextBus"]["EstimatedArrival"]

    case next_bus_time do
      nil ->
        acc

      time ->
        acc ++
          [%{"service_no" => service["ServiceNo"], "time" => TimeUtil.get_eta_in_minutes(time)}]
    end
  end

  def get_incoming_buses(cached_predictions) do
    cached_predictions
    |> Enum.reduce([], &incoming_bus_reducer(&1, &2))
    |> Enum.filter(&(&1["time"] > -1))
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
    case RealTime.get_predictions_cached(bus_stop_no) do
      {:ok, cached_predictions} ->
        cached_predictions = filter_panel_groups(cached_predictions, socket.assigns.panel_id)

        incoming_buses = get_incoming_buses(cached_predictions)

        predictions_previous = socket.assigns.predictions_current
        cached_predictions = update_cached_predictions(cached_predictions, bus_stop_no)

        socket =
          socket
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

        show_scheduled_predictions(
          socket,
          bus_stop_no,
          start_time,
          is_trigger_next,
          is_prediction_next_slide_scheduled
        )

      {:error, error} ->
        Logger.error(
          "Error fetching cached_predictions for bus stop: #{
            inspect({bus_stop_no, bus_stop_name})
          } -> #{inspect(error)}"
        )

        trigger_next_update_stops(is_trigger_next)
        elapsed_time = TimeUtil.get_elapsed_time(start_time)
        Logger.info(":update_stops failed (#{elapsed_time})")
        {:noreply, socket}
    end
  end

  def show_scheduled_predictions(
        socket,
        bus_stop_no,
        start_time,
        is_trigger_next,
        is_prediction_next_slide_scheduled
      ) do
    predictions_previous = socket.assigns.predictions_current

    scheduled_predictions =
      Scheduled.get_predictions(bus_stop_no)
      |> filter_panel_groups(socket.assigns.panel_id)

    incoming_buses =
      scheduled_predictions
      |> Enum.map(fn prediction -> prediction["ServiceNo"] end)
      |> Scheduled.get_incoming_buses(bus_stop_no)

    scheduled_predictions = update_scheduled_predictions(scheduled_predictions)

    socket =
      socket
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

  def update_realtime_destination(service, bus_stop_map) do
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

  def update_realtime_no_of_stops(service, no_of_stops_map) do
    no_of_stops =
      Buses.get_no_of_stops_from_map_by_dpi_route_code_and_dest_code(
        no_of_stops_map,
        {service["ServiceNo"], service["NextBus"]["DestinationCode"] |> String.to_integer()}
      )

    Map.put(service, "NoOfStops", no_of_stops)
  end

  def update_scheduled_destination(service, bus_stop_map) do
    case Access.get(service, "DestinationCode") do
      nil ->
        service

      _ ->
        update_in(
          service,
          ["DestinationCode"],
          &Buses.get_bus_stop_name_from_bus_stop_map(bus_stop_map, &1)
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

    bus_stop_map =
      cached_predictions
      |> Enum.map(fn service ->
        service
        |> get_in(["NextBus", "DestinationCode"])
      end)
      |> Buses.get_bus_stop_map_by_nos()

    no_of_stops_map = Buses.get_no_of_stops_map_by_bus_stop(bus_stop_no)

    cached_predictions
    |> Enum.map(fn service ->
      service
      |> update_realtime_no_of_stops(no_of_stops_map)
      |> update_realtime_destination(bus_stop_map)
    end)
  end

  def update_scheduled_predictions(scheduled_predictions) do
    scheduled_predictions =
      scheduled_predictions
      |> Flow.from_enumerable()
      |> Flow.map(fn prediction ->
        update_scheduled_arrival(prediction)
      end)

    bus_stop_map =
      scheduled_predictions
      |> Enum.map(fn service ->
        service
        |> get_in(["DestinationCode"])
      end)
      |> Buses.get_bus_stop_map_by_nos()

    scheduled_predictions
    |> Enum.map(fn service ->
      service
      |> update_scheduled_destination(bus_stop_map)
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
    case current_layout_index do
      nil ->
        next_layout = Enum.at(layouts, 0)
        next_duration = Map.get(next_layout, "duration") |> String.to_integer()

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

        socket =
          socket
          |> Phoenix.LiveView.assign(:current_layout_value, Map.get(next_layout, "value"))
          |> Phoenix.LiveView.assign(:current_layout_index, 0)
          |> Phoenix.LiveView.assign(:update_layout_timer, update_layout_timer)

        {:noreply, socket}

      current_index ->
        next_index = get_next_index(layouts, current_index)
        next_layout = Enum.at(layouts, next_index)
        next_duration = Map.get(next_layout, "duration") |> String.to_integer()

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

        socket =
          socket
          |> Phoenix.LiveView.assign(:current_layout_value, Map.get(next_layout, "value"))
          |> Phoenix.LiveView.assign(:current_layout_index, next_index)
          |> Phoenix.LiveView.assign(:current_layout_panes, Map.get(next_layout, "panes"))
          |> Phoenix.LiveView.assign(:update_layout_timer, update_layout_timer)

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
end
