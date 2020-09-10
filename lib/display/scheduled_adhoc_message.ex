defmodule Display.ScheduledAdhocMessage do
  def get_message(nil), do: nil

  def get_message(bus_stop_code) do
    # get message from db
    "Formula One Closing"
  end
end
