defmodule Display.ScheduledAdhocMessage do
  def do_checking(nil),do: {:error, :invalid_params}
  def do_checking(bus_stop_code) do
    bus_stop_code
  end
end
