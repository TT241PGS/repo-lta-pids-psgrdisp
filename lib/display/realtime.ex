defmodule Display.RealTime do
  @moduledoc false
  alias Display.{Buses, Poi}
  alias Display.Utils.TimeUtil

  def get_predictions_realtime(bus_stop_id) do
    base_url = Application.get_env(:display, :datamall_base_url)
    url = "#{base_url}/BusArrivalv2?BusStopCode=#{bus_stop_id}"

    headers = [
      {"accountKey", Application.get_env(:display, :datamall_account_key)},
      {"content-type", "application/json"},
      {"Accept", "application/json"}
    ]

    {:ok, predictons} = HTTPWrapper.get(url, headers, [])
    predictons["Services"]
  end

  def get_predictions_cached(bus_stop_id) do
    key = "pids:bus_arrivals"
    cached_data = Display.Redix.command(["HMGET", key, bus_stop_id])

    case cached_data do
      {:ok, [nil]} ->
        {:error, :not_found}

      {:ok, [data]} ->
        data = data |> Jason.decode!()
        {:ok, data}

      {:error, error} ->
        {:error, error}

      any ->
        {:error, any}
    end
  end

  @doc """
  Get quickest way to of last bus of each service in a bus_stop
  Example:
  [
    %{
      "arriving_time_at_destination" => 59122,
      "arriving_time_at_origin" => "36 min",
      "poi_name" => "W'Lands Train Checkpt",
      "service_no" => "912"
    }
  ]
  """

  def get_quickest_way_to(_bus_stop_no, _service_arrival_map, %{global_message: global_message})
      when is_bitstring(global_message) do
    []
  end

  def get_quickest_way_to(bus_stop_no, service_arrival_map, %{
        service_message_map: service_message_map,
        hide_services: hide_services
      }) do
    %Postgrex.Result{rows: rows} = Buses.get_realtime_quickest_way_to_by_bus_stop(bus_stop_no)

    suppress_services = Map.keys(service_message_map) ++ hide_services

    rows
    |> Enum.filter(fn [_, dpi_route_code, _] -> dpi_route_code not in suppress_services end)
    |> Enum.reduce(%{}, fn [poi_stop_code, dpi_route_code, travel_time], acc ->
      key = poi_stop_code

      service_arrival_time =
        case Map.get(service_arrival_map, dpi_route_code) do
          nil -> 100_000
          arrival_time -> TimeUtil.get_seconds_past_today_from_iso_date(arrival_time)
        end

      value = %{
        "arriving_time_at_origin" => service_arrival_time,
        "arriving_time_at_destination" => travel_time + service_arrival_time,
        "service_no" => dpi_route_code
      }

      case Map.get(acc, key) do
        nil ->
          Map.put(acc, key, [value])

        _ ->
          update_in(acc, [key], &(&1 ++ [value]))
      end
    end)
    |> determine_quickest_way_to
    |> add_poi_metadata()
  end

  defp determine_quickest_way_to(quickest_way_to_map) do
    quickest_way_to_map
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      value =
        Enum.sort(
          v,
          &(&1["arriving_time_at_destination"] - &2["arriving_time_at_destination"] < 240)
        )
        |> List.first()

      Map.put(acc, k, value)
    end)
  end

  defp add_poi_metadata(quickest_way_to_map) do
    poi_metadata_map =
      Enum.map(quickest_way_to_map, fn {k, _v} -> k end)
      |> Poi.get_poi_metadata_map()

    Enum.map(quickest_way_to_map, fn {k, v} ->
      v
      |> Map.put("poi_name", Map.get(poi_metadata_map, k))
      |> update_in(["arriving_time_at_origin"], &TimeUtil.get_eta_from_seconds_past_today/1)
    end)
  end
end
