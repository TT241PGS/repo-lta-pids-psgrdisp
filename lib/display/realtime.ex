defmodule Display.RealTime do
  @moduledoc false

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
end
