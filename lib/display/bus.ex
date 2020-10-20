defmodule Display.Buses do
  @moduledoc false

  import Ecto.Query, warn: false
  use Timex
  alias Display.{Buses, Repo}
  alias Display.Utils.TimeUtil
  alias Ecto.Adapters.SQL

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

  def get_bus_stop_from_panel_id(nil), do: nil

  def get_bus_stop_from_panel_id(panel_id) do
    from(pb in Buses.PanelBus,
      where: pb.panel_id == ^panel_id,
      select: %{
        panel_id: pb.panel_id,
        bus_stop_no: pb.bus_stop_no
      }
    )
    |> Repo.one()
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

  # TODO: Query with BaseVersion, OperatingDay
  def get_bus_schedule_by_bus_stop(bus_stop_no) do
    now_in_seconds_past_today = TimeUtil.get_seconds_past_today()

    query = "
    select distinct bs_outer.dpi_route_code, bs_outer.direction, bs_top.arriving_time from bus_schedule bs_outer
    join lateral (
      select * from bus_schedule bs_inner
      where bs_inner.dpi_route_code = bs_outer.dpi_route_code
      and bs_inner.point_no = #{bus_stop_no}
      and bs_inner.arriving_time > #{now_in_seconds_past_today}
      order by bs_inner.arriving_time
      limit 3
    ) bs_top on true
    where bs_outer.point_no = #{bus_stop_no}
    order by bs_outer.dpi_route_code
    "
    SQL.query!(Repo, query, [])
  end

  # TODO: Query with BaseVersion, OperatingDay
  def get_incoming_bus_schedule_by_bus_stop(bus_stop_no) do
    now_in_seconds_past_today = TimeUtil.get_seconds_past_today()

    query = "
    select distinct bs_outer.dpi_route_code, bs_top.arriving_time from bus_schedule bs_outer
    join lateral (
        select * from bus_schedule bs_inner
        where bs_inner.dpi_route_code = bs_outer.dpi_route_code
        and bs_inner.point_no = #{bus_stop_no}
        and bs_inner.arriving_time > #{now_in_seconds_past_today}
        order by bs_inner.arriving_time
        limit 1
    ) bs_top on true
    where bs_outer.point_no = #{bus_stop_no}
    order by bs_outer.dpi_route_code
    limit 5;
    "
    SQL.query!(Repo, query, [])
  end

  # TODO: Query with BaseVersion, OperatingDay
  def get_last_bus_by_service_by_bus_stop(bus_stop_no) do
    query = "
    select distinct bs_outer.dpi_route_code, bs_outer.direction, bs_top.arriving_time from bus_schedule bs_outer
    join lateral (
        select * from bus_schedule bs_inner
        where bs_inner.dpi_route_code = bs_outer.dpi_route_code
        and bs_inner.point_no = #{bus_stop_no}
        order by bs_inner.arriving_time desc
        limit 1
    ) bs_top on true
    where bs_outer.point_no = #{bus_stop_no}
    order by bs_outer.dpi_route_code
    limit 5;
    "
    SQL.query!(Repo, query, [])
  end

  # TODO: Query with BaseVersion
  def get_all_services_by_bus_stop(bus_stop_no) do
    query = "
    select distinct dpi_route_code, direction from bus_schedule
    where point_no = #{bus_stop_no}
    "
    SQL.query!(Repo, query, [])
  end
end
