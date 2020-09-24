defmodule Display.Buses do
  @moduledoc false

  import Ecto.Query, warn: false
  alias Display.{Buses, Repo}

  def get_bus_stop_name_by_no(nil), do: nil

  # This should be cached as its expensive
  def get_bus_stop_name_by_no(bus_stop_no) do
    from(bs in Buses.BusStop,
      where: bs.point_no == ^bus_stop_no,
      select: %{
        point_no: bs.point_no,
        point_desc: bs.point_desc
      }
    )
    |> Repo.one()
    |> get_in([:point_desc])
  end

  def get_bus_stop_map_by_nos(bus_stop_nos) do
    from(bs in Buses.BusStop,
      where: bs.point_no in ^bus_stop_nos,
      select: %{
        point_no: bs.point_no,
        point_desc: bs.point_desc
      }
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn bus_stop, acc -> Map.put(acc, bus_stop.point_no, bus_stop) end)
  end

  def get_bus_stop_name_from_bus_stop_map(bus_stop_map, bus_stop_no) do
    Map.get(bus_stop_map, bus_stop_no)
    |> Map.get(:point_desc)
  end
end
