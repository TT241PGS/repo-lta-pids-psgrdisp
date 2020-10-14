defmodule Display.Utils.DisplayLiveUtil do
  @moduledoc false

  alias Display.{Buses, Templates}
  alias Display.Utils.TimeUtil

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

  def get_template_details_from_cms(panel_id) do
    Templates.list_templates_by_panel_id(panel_id)
    |> Enum.map(fn template ->
      template
      |> get_in([:template_detail])
      |> Jason.decode!()
    end)
  end

  def create_stop_predictions_set_1_column(cached_predictions) do
    create_stop_predictions_columnwise(cached_predictions, 5)
  end

  def create_stop_predictions_set_2_column(cached_predictions) do
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

  def update_estimated_arrival(service, next_bus) do
    case Access.get(service, next_bus) do
      nil ->
        service

      _ ->
        update_in(service, [next_bus, "EstimatedArrival"], &TimeUtil.format_time_to_eta_mins(&1))
    end
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

  def get_next_index(layouts, current_index) do
    max_index = length(layouts) - 1

    cond do
      current_index < max_index -> current_index + 1
      current_index == max_index -> 0
      true -> 0
    end
  end
end
