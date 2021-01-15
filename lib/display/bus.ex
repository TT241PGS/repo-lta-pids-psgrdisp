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

  def get_no_of_stops_map_by_bus_stop(bus_stop) do
    from(s in Buses.Schedule,
      where: s.point_no == ^bus_stop,
      distinct: [s.dpi_route_code, s.dest_code, s.no_of_stops]
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn service, acc ->
      Map.put(acc, {service.dpi_route_code, service.dest_code}, service.no_of_stops)
    end)
  end

  def get_no_of_stops_from_map_by_dpi_route_code_and_dest_code(
        no_of_stops_map,
        {dpi_route_code, dest_code}
      ) do
    Map.get(no_of_stops_map, {dpi_route_code, dest_code})
  end

  # TODO: Query with BaseVersion, OperatingDay
  def get_bus_schedule_by_bus_stop(bus_stop_no) do
    now_in_seconds_past_today = TimeUtil.get_seconds_past_today()

    query = "
    select distinct bs_outer.dpi_route_code, bs_outer.dest_code, bs_top.arriving_time from schedule bs_outer
    join lateral (
      select * from schedule bs_inner
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
    select distinct bs_outer.dpi_route_code, bs_top.arriving_time from schedule bs_outer
    join lateral (
        select * from schedule bs_inner
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
    select distinct bs_outer.dpi_route_code, bs_outer.dest_code, bs_top.arriving_time from schedule bs_outer
    join lateral (
        select * from schedule bs_inner
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
    select distinct dpi_route_code, dest_code from schedule
    where point_no = #{bus_stop_no}
    "
    SQL.query!(Repo, query, [])
  end

  def get_panel_configuration_by_panel_id(panel_id) do
    from(p in Buses.PanelConfiguration,
      where: p.panel_id == ^panel_id
    )
    |> Repo.one()
  end

  # TODO: Query with BaseVersion, OperatingDay
  def get_scheduled_quickest_way_to_by_bus_stop(bus_stop_no) do
    now_in_seconds_past_today = TimeUtil.get_seconds_past_today()
    query = "
    select distinct t_top.service, t_outer.poi_stop, t_top.time_period, t_top.time_taken from quickest_way_to_poi t_outer
    join lateral (
        select * from quickest_way_to_poi t_inner
        where t_inner.departure_stop = t_outer.departure_stop
        and t_inner.poi_stop = t_outer.poi_stop
        and t_inner.time_period > #{now_in_seconds_past_today}
        order by t_inner.time_period asc
        limit 2
    ) t_top on true
    where t_outer.departure_stop=#{bus_stop_no}
    order by t_top.time_period,t_outer.poi_stop
    limit 4;
    "
    SQL.query!(Repo, query, [])
  end

  # TODO: Query with BaseVersion, OperatingDay
  # Get next 5 services each going to every POI stop from a bus stop
  def get_realtime_quickest_way_to_by_bus_stop(bus_stop_no) do
    now_in_seconds_past_today = TimeUtil.get_seconds_past_today()
    next_hour_in_seconds_past_today = now_in_seconds_past_today * 60
    query = "
    select distinct t_outer.poi_stop, t_top.service, t_top.time_taken from quickest_way_to_poi t_outer
    join lateral (
        select * from quickest_way_to_poi t_inner
        where t_inner.departure_stop = t_outer.departure_stop
        and t_inner.poi_stop = t_outer.poi_stop
        and t_inner.time_period > #{now_in_seconds_past_today}
        and t_inner.time_period <= #{next_hour_in_seconds_past_today}
        order by t_inner.time_period
        limit 5
    ) t_top on true
    where t_outer.departure_stop=#{bus_stop_no}
    group by t_outer.poi_stop,t_top.service,t_top.time_taken
    "
    SQL.query!(Repo, query, [])
  end

  def get_poi_metadata_map(poi_list) do
    from(p in Buses.PoiStop,
      where: p.stop_code in ^poi_list
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn poi, acc ->
      Map.put(acc, poi.stop_code, poi.poi_name)
    end)
  end
end
