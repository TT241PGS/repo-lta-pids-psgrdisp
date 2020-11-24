defmodule Display.Utils.DisplayLiveUtil do
  @moduledoc false

  require Logger

  alias Display.{Buses, RealTime, Templates}
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
        is_trigger_next
      ) do
    case RealTime.get_predictions_cached(bus_stop_no) do
      {:ok, cached_predictions} ->
        incoming_buses = get_incoming_buses(cached_predictions)

        predictions_previous = socket.assigns.predictions_current
        cached_predictions = update_cached_predictions(cached_predictions)

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
        trigger_prediction_slider(predictions_previous, cached_predictions)

        elapsed_time = TimeUtil.get_elapsed_time(start_time)
        Logger.info(":update_stops ended successfully (#{elapsed_time})")
        {:noreply, socket}

      {:error, :not_found} ->
        Logger.error(
          "Cached_predictions :not_found for bus stop: #{inspect({bus_stop_no, bus_stop_name})}"
        )

        show_scheduled_predictions(socket, bus_stop_no, start_time, is_trigger_next)

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

  def show_scheduled_predictions(socket, bus_stop_no, start_time, is_trigger_next) do
    predictions_previous = socket.assigns.predictions_current

    scheduled_predictions = Display.Scheduled.get_predictions(bus_stop_no)

    incoming_buses = Display.Scheduled.get_incoming_buses(bus_stop_no)

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
    trigger_prediction_slider(predictions_previous, scheduled_predictions)

    elapsed_time = TimeUtil.get_elapsed_time(start_time)
    Logger.info(":update_stops failed (#{elapsed_time})")
    {:noreply, socket}
  end

  def trigger_next_update_stops(is_trigger) do
    if is_trigger == true do
      Process.send_after(self(), :update_stops_repeatedly, 30_000)
    end
  end

  defp trigger_prediction_slider(predictions_previous, predictions_current) do
    cond do
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
    create_predictions_columnwise(cached_predictions, 5)
  end

  def create_predictions_set_2_column(cached_predictions) do
    create_predictions_columnwise(cached_predictions, 10)
  end

  defp create_predictions_columnwise(cached_predictions, max_rows) do
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

  def update_destination(service, bus_stop_map) do
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

  def update_cached_predictions(cached_predictions) do
    cached_predictions =
      cached_predictions
      |> Flow.from_enumerable()
      |> Flow.map(fn service ->
        service
        |> update_estimated_arrival("NextBus")
        |> update_estimated_arrival("NextBus2")
        |> update_estimated_arrival("NextBus3")
      end)
      |> Enum.sort_by(
        fn p ->
          NaturalSort.format_item(p["ServiceNo"], false)
        end,
        NaturalSort.sort_direction(:asc)
      )

    bus_stop_map =
      cached_predictions
      |> Enum.map(fn service ->
        service
        |> get_in(["NextBus", "DestinationCode"])
      end)
      |> Buses.get_bus_stop_map_by_nos()

    cached_predictions
    |> Enum.map(fn service ->
      service
      |> update_destination(bus_stop_map)
    end)
  end

  def update_scheduled_predictions(scheduled_predictions) do
    scheduled_predictions
    |> Flow.from_enumerable()
    |> Flow.map(fn prediction ->
      update_scheduled_arrival(prediction)
    end)
    |> Enum.sort_by(
      fn p ->
        NaturalSort.format_item(p["ServiceNo"], false)
      end,
      NaturalSort.sort_direction(:asc)
    )
  end

  def get_next_index(layouts, current_index) do
    max_index = length(layouts) - 1

    cond do
      current_index < max_index -> current_index + 1
      current_index == max_index -> 0
      true -> 0
    end
  end
end
