defmodule Display.RealTime do
  @moduledoc false
  alias Display.{Buses, Poi, QuickestWayTo}
  alias Display.Utils.TimeUtil

  def get_predictions_cached(bus_stop_id) do
    key = "pids:bus_arrivals"
    cached_data = Display.Redix.command(["HMGET", key, bus_stop_id])

    case cached_data do
      {:ok, [nil]} ->
        {:error, :not_found}

      {:ok, [data]} ->
        data = data |> Jason.decode!() |> split_by_visit_no()
        {:ok, data}

      {:error, error} ->
        {:error, error}

      any ->
        {:error, any}
    end
  end

  def get_predictions_cached_mock(_bus_stop_id) do
    # This data is for bus stop 66271
    {:ok,
     [
       %{
         "NextBus" => %{
           "DestinationCode" => "66009",
           "EstimatedArrival" => "2021-04-01T00:49:44+08:00",
           "Feature" => "WAB",
           "Latitude" => "1.3499598333333334",
           "Load" => "SEA",
           "Longitude" => "103.87156483333334",
           "OriginCode" => "66009",
           "Type" => "SD",
           "VisitNumber" => "1"
         },
         "NextBus2" => %{
           "DestinationCode" => "66009",
           "EstimatedArrival" => "2021-04-01T00:58:56+08:00",
           "Feature" => "WAB",
           "Latitude" => "0.0",
           "Load" => "SEA",
           "Longitude" => "0.0",
           "OriginCode" => "66009",
           "Type" => "SD",
           "VisitNumber" => "1"
         },
         "ServiceNo" => "315"
       },
       %{
         "NextBus" => %{
           "DestinationCode" => "66009",
           "EstimatedArrival" => "2021-04-01T00:46:12+08:00",
           "Feature" => "WAB",
           "Latitude" => "1.3654725",
           "Load" => "SEA",
           "Longitude" => "103.8723365",
           "OriginCode" => "66009",
           "Type" => "SD",
           "VisitNumber" => "2"
         },
         "ServiceNo" => "315"
       },
       %{
         "NextBus" => %{
           "DestinationCode" => "66009",
           "EstimatedArrival" => "2021-04-01T00:47:27+08:00",
           "Feature" => "WAB",
           "Latitude" => "1.3511186666666666",
           "Load" => "SEA",
           "Longitude" => "103.87495683333331",
           "OriginCode" => "66009",
           "Type" => "SD",
           "VisitNumber" => "1"
         },
         "ServiceNo" => "317"
       },
       %{
         "NextBus" => %{
           "DestinationCode" => "66009",
           "EstimatedArrival" => "2021-04-01T00:45:04+08:00",
           "Feature" => "WAB",
           "Latitude" => "1.3642665",
           "Load" => "SEA",
           "Longitude" => "103.86118516666669",
           "OriginCode" => "66009",
           "Type" => "SD",
           "VisitNumber" => "2"
         },
         "NextBus2" => %{
           "DestinationCode" => "66009",
           "EstimatedArrival" => "2021-04-01T00:56:04+08:00",
           "Feature" => "WAB",
           "Latitude" => "1.3511186666666666",
           "Load" => "SEA",
           "Longitude" => "103.87495683333331",
           "OriginCode" => "66009",
           "Type" => "SD",
           "VisitNumber" => "2"
         },
         "ServiceNo" => "317"
       }
     ]}
  end

  defp split_by_visit_no(predictions) do
    predictions
    |> Enum.reduce([], fn service, acc ->
      visit_no_map = %{}

      visit_no_map =
        if is_map(Access.get(service, "NextBus")),
          do:
            update_in(visit_no_map, [service["NextBus"]["VisitNumber"]], fn
              _ ->
                %{
                  "ServiceNo" => service["ServiceNo"],
                  "NextBus" => service["NextBus"]
                }
            end),
          else: visit_no_map

      visit_no_map =
        if is_map(Access.get(service, "NextBus2")),
          do:
            update_in(visit_no_map, [service["NextBus2"]["VisitNumber"]], fn
              nil ->
                %{
                  "ServiceNo" => service["ServiceNo"],
                  "NextBus" => service["NextBus2"]
                }

              new_service ->
                Map.put(new_service, "NextBus2", service["NextBus2"])
            end),
          else: visit_no_map

      visit_no_map =
        if is_map(Access.get(service, "NextBus3")),
          do:
            update_in(visit_no_map, [service["NextBus3"]["VisitNumber"]], fn
              nil ->
                %{
                  "ServiceNo" => service["ServiceNo"],
                  "NextBus" => service["NextBus3"]
                }

              %{"NextBus2" => _next_bus_2} = new_service ->
                Map.put(new_service, "NextBus3", service["NextBus3"])

              new_service ->
                Map.put(new_service, "NextBus2", service["NextBus3"])
            end),
          else: visit_no_map

      acc ++
        Enum.map(visit_no_map, fn {_k, v} ->
          v
        end)
    end)
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
    |> Enum.filter(fn [_, dpi_route_code, _, _] -> dpi_route_code not in suppress_services end)
    |> Enum.reduce(%{}, fn [poi_stop_code, dpi_route_code, visit_no, travel_time], acc ->
      key = poi_stop_code

      service_arrival_time =
        case Map.get(service_arrival_map, dpi_route_code) do
          nil -> 100_000
          arrival_time -> TimeUtil.get_seconds_past_today_from_iso_date(arrival_time)
        end

      value = %{
        "arriving_time_at_origin" => service_arrival_time,
        "arriving_time_at_destination" => travel_time + service_arrival_time,
        "service_no" => dpi_route_code,
        "visit_no" => visit_no,
        "type" => "main"
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
    |> QuickestWayTo.transform_quickest_way_to(bus_stop_no)
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
      |> Map.put("poi", Map.get(poi_metadata_map, k))
      |> update_in(["arriving_time_at_origin"], &TimeUtil.get_eta_from_seconds_past_today/1)
    end)
  end

  def set_last_bus(realtime_predictions, last_bus_map) do
    realtime_predictions
    |> Enum.map(fn service ->
      cond do
        Access.get(service, "NextBus2") |> is_nil && Access.get(service, "NextBus3") |> is_nil ->
          put_in(
            service,
            ["NextBus", "isLastBus"],
            is_last_bus?(service["ServiceNo"], service["NextBus"], last_bus_map)
          )

        Access.get(service, "NextBus3") |> is_nil ->
          put_in(
            service,
            ["NextBus2", "isLastBus"],
            is_last_bus?(service["ServiceNo"], service["NextBus2"], last_bus_map)
          )

        true ->
          put_in(service, ["NextBus", "isLastBus"], false)
      end
    end)
  end

  defp is_last_bus?(service_no, next_bus, last_bus_map) do
    dest_code = next_bus["DestinationCode"]
    last_bus = get_in(last_bus_map, [{service_no, dest_code |> String.to_integer()}])
    next_bus_time = next_bus["EstimatedArrival"]

    case Access.get(last_bus, "time_iso") do
      nil ->
        false

      last_bus_time ->
        # TRUE if next bus arrival time is after one minute less than scheduled last bus arrival time
        # One minute buffer to show last bus, buffer is needed as the last bus would have already left the stop otherwise
        # So last bus will be shown just before a minute of scheduled last bus arrival time
        Timex.after?(
          DateTime.from_iso8601(next_bus_time) |> elem(1),
          DateTime.from_iso8601(last_bus_time) |> elem(1) |> DateTime.add(-60, :second)
        )
    end
  end
end
