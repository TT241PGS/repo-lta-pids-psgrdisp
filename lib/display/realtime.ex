defmodule Display.RealTime do
  def get_predictions(bus_stop_id) do
    base_url = "http://datamall2.mytransport.sg/ltaodataservice"
    url = "#{base_url}/BusArrivalv2?BusStopCode=#{bus_stop_id}"
    headers = [
      {
        "content-type", "application/json"
      },
      {
        "accountKey", "ksy0XzCCRyCnOXTAFKC13w=="
      }
    ]
    
    {:ok, predictons} = HTTPWrapper.get(url, headers, [])
    predictons["Services"]
  end
end
