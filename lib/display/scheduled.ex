defmodule Display.Scheduled do
  @moduledoc false

  alias Display.{Buses, Utils}

  @doc """
  Returns a list of services with next 3 buses in each service
  Example:
  [
    %{
      "Direction" => 1,
      "NextBuses" => [
        %{"EstimatedArrival" => "2020-10-15T20:55:19+08:00"},
        %{"EstimatedArrival" => "2020-10-15T20:55:31+08:00"},
        %{"EstimatedArrival" => "2020-10-15T20:55:36+08:00"}
      ],
      "ServiceNo" => "2"
    }
  ]
  """
  def get_predictions(bus_stop_no) do
    %Postgrex.Result{rows: rows} = Buses.get_bus_schedule_by_bus_stop(bus_stop_no)

    rows
    |> Enum.reduce(%{}, fn row, acc ->
      [dpi_route_code, direction, arriving_time] = row
      key = {dpi_route_code, direction}

      arriving_time_formatted = Utils.TimeUtil.get_iso_date_from_seconds(arriving_time)

      value = [%{"EstimatedArrival" => arriving_time_formatted}]

      case Map.get(acc, key) do
        nil -> Map.put(acc, key, value)
        item -> update_in(acc, [key], &(&1 ++ value))
      end
    end)
    |> Enum.map(fn {{service_no, direction}, value} ->
      %{
        "ServiceNo" => service_no,
        "Direction" => direction,
        "NextBuses" => value
      }
    end)
  end
end
