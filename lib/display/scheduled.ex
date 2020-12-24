defmodule Display.Scheduled do
  @moduledoc false

  alias Display.Buses
  alias Display.Utils.TimeUtil

  @doc """
  Returns a list of services with next 3 buses in each service
  Example:
  [
    %{
      "Direction" => 1,
      "NextBuses" => [],
      "ServiceNo" => "17",
      "Status" => "last_trip_departed"
    },
    %{
      "Direction" => 2,
      "NextBuses" => [
        %{"EstimatedArrival" => "2020-10-19T22:12:00+08:00", "isLastBus" => false},
        %{"EstimatedArrival" => "2020-10-19T22:27:34+08:00", "isLastBus" => false},
        %{"EstimatedArrival" => "2020-10-19T22:43:34+08:00", "isLastBus" => true}
      ],
      "ServiceNo" => "42",
      "Status" => "operating_now"
    }
  ]
  """
  def get_predictions(bus_stop_no) do
    [
      Task.async(fn -> get_active_services_map(bus_stop_no) end),
      Task.async(fn -> get_last_buses_map(bus_stop_no) end),
      Task.async(fn -> get_all_services(bus_stop_no) end)
    ]
    |> Task.yield_many(5000)
    |> Enum.map(fn {_, res} ->
      case res do
        {:ok, data} -> data
        _ -> nil
      end
    end)
    |> merge_active_inactive_services()
  end

  @doc """
  Returns map of {service_no, direction} with next 3 buses and operational status
  Example:
  %{
    {"30", 2} => %{
      "NextBuses" => [
        %{"EstimatedArrival" => "2020-10-19T14:50:36+08:00"},
        %{"EstimatedArrival" => "2020-10-19T14:58:36+08:00"},
        %{"EstimatedArrival" => "2020-10-19T15:07:36+08:00"}
      ],
      "Status" => "operating_now"
    },
    {"42", 2} => %{
      "NextBuses" => [
        %{"EstimatedArrival" => "2020-10-19T14:50:34+08:00"},
        %{"EstimatedArrival" => "2020-10-19T15:02:34+08:00"},
        %{"EstimatedArrival" => "2020-10-19T15:15:34+08:00"}
      ],
      "Status" => "operating_now"
    }
  }
  """
  defp get_active_services_map(bus_stop_no) do
    %Postgrex.Result{rows: rows} = Buses.get_bus_schedule_by_bus_stop(bus_stop_no)

    rows
    |> Enum.reduce(%{}, fn row, acc ->
      [dpi_route_code, dest_code, no_of_stops, arriving_time] = row
      key = {dpi_route_code, dest_code}

      arriving_time_formatted = TimeUtil.get_iso_date_from_seconds(arriving_time)

      value = %{
        "Status" => "operating_now",
        "NoOfStops" => no_of_stops,
        "NextBuses" => [
          %{
            "EstimatedArrival" => arriving_time_formatted
          }
        ]
      }

      case Map.get(acc, key) do
        nil -> Map.put(acc, key, value)
        _ -> update_in(acc, [key, "NextBuses"], &(&1 ++ value["NextBuses"]))
      end
    end)
  end

  defp merge_active_inactive_services([active_services_map, last_buses_map, all_services]) do
    all_services
    |> Enum.map(fn key ->
      {service_no, dest_code} = key
      current_service = Map.get(active_services_map, key)
      # If current_service is not nil, then bus has upcoming trips
      is_operating_now = if current_service == nil, do: false, else: true
      # If last bus timing is not available in vdv, then the bus is not operating today
      is_operating_today = if Map.get(last_buses_map, key) == nil, do: false, else: true

      cond do
        # last_trip_departed
        is_operating_today and not is_operating_now ->
          %{
            "ServiceNo" => service_no,
            "DestinationCode" => dest_code,
            "Status" => "last_trip_departed",
            "NextBuses" => []
          }

        # not_operating_today
        not is_operating_today ->
          %{
            "ServiceNo" => service_no,
            "DestinationCode" => dest_code,
            "Status" => "not_operating_today",
            "NextBuses" => []
          }

        # operating_now
        true ->
          next_buses = add_last_bus_flag(current_service, key, last_buses_map)

          %{
            "ServiceNo" => service_no,
            "DestinationCode" => dest_code,
            "NoOfStops" => current_service["NoOfStops"],
            "Status" => "operating_now",
            "NextBuses" => next_buses
          }
      end
    end)
  end

  @doc """
  Get immediate next bus of each service
  Returns a list of services with formatted eta
  Example:
  [
    %{"service_no" => "42", "time" => "Arr"},
    %{"service_no" => "30", "time" => "7 min"}
  ]
  """
  def get_incoming_buses(filter_service_groups, bus_stop_no) do
    %Postgrex.Result{rows: rows} = Buses.get_incoming_bus_schedule_by_bus_stop(bus_stop_no)

    rows
    |> Enum.filter(fn [dpi_route_code, _] -> dpi_route_code in filter_service_groups end)
    |> Enum.map(fn [dpi_route_code, arriving_time] ->
      %{"service_no" => dpi_route_code, "time" => arriving_time}
    end)
    |> Enum.sort_by(&{&1["time"], &1["service_no"]})
    |> Enum.map(fn incoming_bus ->
      update_in(incoming_bus, ["time"], &TimeUtil.get_eta_from_seconds_past_today(&1))
    end)
  end

  @doc """
  Get timing of last bus of each service in a bus_stop
  Returns a map with key {service_no, direction}
  Example:
  %{
    {"17", 1} => %{
      "time_iso" => "2020-10-19T06:12:13+08:00",
      "time_seconds" => 22333
    },
    {"30", 2} => %{
      "time_iso" => "2020-10-20T00:01:04+08:00",
      "time_seconds" => 86464
    }
  }
  """
  def get_last_buses_map(bus_stop_no) do
    %Postgrex.Result{rows: rows} = Buses.get_last_bus_by_service_by_bus_stop(bus_stop_no)

    rows
    |> Enum.reduce(%{}, fn [dpi_route_code, dest_code, arriving_time], acc ->
      key = {dpi_route_code, dest_code}

      value = %{
        "time_seconds" => arriving_time,
        "time_iso" => TimeUtil.get_iso_date_from_seconds(arriving_time)
      }

      Map.put(acc, key, value)
    end)
  end

  @doc """
  Get services in a bus_stop for a particular base_version
  Returns a list of {service_no, direction} tuple
  Example: [{"17", 1}, {"30", 2}, {"31", 2}, {"42", 2}]
  """
  def get_all_services(bus_stop_no) do
    %Postgrex.Result{rows: rows} = Buses.get_all_services_by_bus_stop(bus_stop_no)
    Enum.map(rows, &List.to_tuple(&1))
  end

  defp add_last_bus_flag(service, key, last_buses_map) do
    last_index = length(service["NextBuses"]) - 1

    service["NextBuses"]
    |> Enum.with_index()
    |> Enum.map(fn {next_bus, index} ->
      timing_iso = next_bus["EstimatedArrival"]
      last_bus_timing_iso = get_in(last_buses_map, [key, "time_iso"])

      case timing_iso == last_bus_timing_iso and index == last_index do
        true ->
          Map.put(next_bus, "isLastBus", true)

        _ ->
          Map.put(next_bus, "isLastBus", false)
      end
    end)
  end
end
