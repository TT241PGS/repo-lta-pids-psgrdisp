defmodule Display.RealTime do
  def get_predictions_realtime(bus_stop_id) do
    base_url = "http://datamall2.mytransport.sg/ltaodataservice"
    url = "#{base_url}/BusArrivalv2?BusStopCode=#{bus_stop_id}"

    headers = [
      {
        "content-type",
        "application/json"
      },
      {
        "accountKey",
        "ksy0XzCCRyCnOXTAFKC13w=="
      }
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
end
