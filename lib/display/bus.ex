defmodule Display.Buses do
  @moduledoc false

  import Ecto.Query, warn: false
  use Timex
  alias Display.{Buses, Repo, Meta, Poi}
  alias Display.Utils.TimeUtil
  alias Ecto.Adapters.SQL
  alias DisplayWeb.DisplayLive.Utils

  def get_bus_stop_name_by_no(nil), do: nil

  def get_bus_stop_name_by_no(bus_stop_no) do
    result =
      from(bs in Buses.BusStop,
        join: bv in Meta.BaseVersion,
        on: bv.base_version == bs.base_version,
        where: bv.status == "live" and bs.point_no == ^bus_stop_no and bs.point_type == 1,
        select: %{
          point_no: bs.point_no,
          point_desc: bs.point_desc
        }
      )
      |> Repo.all()

    case result do
      [] -> nil
      [one] -> get_in(one, [:point_desc])
      _ -> nil
    end
  end

  def get_bus_hub_name_by_no(nil), do: nil

  def get_bus_hub_name_by_no(bus_stop_no) do
    result =
      from(bs in Buses.BushubInterchange,
        where: bs.point_no == ^bus_stop_no,
        select: %{
          stop_name: bs.stop_name
        },
        limit: 1
      )
      |> Repo.all()

    case result do
      [] -> nil
      [one] -> get_in(one, [:stop_name])
      _ -> nil
    end
  end

  def get_bus_hub_or_stop_name_by_no(nil), do: nil

  def get_bus_hub_or_stop_name_by_no(bus_stop_no) do
    case get_bus_hub_name_by_no(bus_stop_no) do
      nil -> get_bus_stop_name_by_no(bus_stop_no)
      stop_name -> stop_name
    end
  end

  # BusInterchange will always have berth_label
  # Don't need to consider direction and visit no as it will be null
  def get_bus_interchange_service_mapping_by_no(bus_stop_no) do
    result =
      from(bs in Buses.BushubInterchange,
        where: bs.point_no == ^bus_stop_no and not is_nil(bs.berth_label),
        distinct: [
          bs.dpi_route_code,
          # bs.direction,
          # bs.visit_no,
          bs.berth_label,
          bs.destination,
          bs.way_points
        ]
      )
      |> Repo.all()

    cond do
      is_list(result) ->
        result
        |> Enum.reduce(%{}, fn service, acc ->
          update_in(acc, [service.dpi_route_code], fn _ ->
            waypoints = Poi.format_bushub_interchange_waypoints(service.way_points)

            %{
              "berth_label" => service.berth_label,
              "destination" => service.destination,
              "way_points" => waypoints
            }
          end)
        end)

      true ->
        %{}
    end
  end

  # BusHub will not have berth_label
  # Visit no could be null, expecting direction to be non null
  def get_bus_hub_service_mapping_by_no(bus_stop_no) do
    result =
      from(bs in Buses.BushubInterchange,
        where: bs.point_no == ^bus_stop_no and is_nil(bs.berth_label),
        distinct: [
          bs.dpi_route_code,
          bs.direction,
          bs.visit_no,
          bs.destination,
          bs.way_points
        ]
      )
      |> Repo.all()

    cond do
      is_list(result) ->
        result
        |> Enum.reduce(%{}, fn service, acc ->
          update_in(acc, [{service.dpi_route_code, service.direction, service.visit_no}], fn _ ->
            waypoints = Poi.format_bushub_interchange_waypoints(service.way_points)

            %{
              "destination" => service.destination,
              "way_points" => waypoints
            }
          end)
        end)

      true ->
        %{}
    end
  end

  def get_bus_direction_from_destination_code(nil), do: nil

  def get_service_direction_map(bus_stop_no) do
    from(s in Buses.Schedule,
      distinct: [s.dpi_route_code, s.line_no, s.dest_code, s.direction],
      join: b in Meta.BaseVersion,
      on: s.base_version == b.base_version,
      where: s.point_no == ^bus_stop_no and b.status == "live"
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn service, acc ->
      service_no =
        case is_nil(service.dpi_route_code) do
          true -> service.line_no |> Integer.to_string()
          _ -> service.dpi_route_code
        end

      Map.put(
        acc,
        {service_no, service.dest_code},
        service.direction
      )
    end)
  end

  def get_bus_stop_from_panel_id(nil), do: nil

  def get_bus_stop_from_panel_id(panel_id) do
    from(pb in Buses.PanelBusStop,
      where: pb.panel_id == ^panel_id,
      select: %{
        panel_id: pb.panel_id,
        bus_stop_no: pb.point_no
      }
    )
    |> Repo.one()
  end

  def get_bus_stop_map_by_nos(bus_stop_nos) do
    bus_stop_nos = Utils.swap_dest_code_list(bus_stop_nos)

    from(bs in Buses.BusStop,
      join: bv in Meta.BaseVersion,
      on: bv.base_version == bs.base_version,
      where: bv.status == "live" and bs.point_no in ^bus_stop_nos and bs.point_type == 1,
      select: %{
        point_no: bs.point_no,
        point_desc: bs.point_desc
      }
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn bus_stop, acc -> Map.put(acc, bus_stop.point_no, bus_stop) end)
  end

  def get_bus_stop_name_from_bus_stop_map(bus_stop_map, bus_stop_no) do
    case Map.get(bus_stop_map, bus_stop_no) do
      nil -> bus_stop_no
      point -> Map.get(point, :point_desc)
    end
  end

  def get_no_of_stops_map_by_bus_stop(bus_stop_no) do
    from(s in Buses.Schedule,
      distinct: [s.dpi_route_code, s.dest_code, s.no_of_stops],
      join: b in Meta.BaseVersion,
      on: s.base_version == b.base_version,
      where: s.point_no == ^bus_stop_no and b.status == "live"
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

  @doc """
  Get timing of last bus of each service in a bus_stop
  Returns a map with key {service_no, dest_code}
  Example:
  %{
    {"17", 17009} => %{
      "time_iso" => "2020-10-19T06:12:13+08:00",
      "time_seconds" => 22333
    },
    {"30", 17009} => %{
      "time_iso" => "2020-10-20T00:01:04+08:00",
      "time_seconds" => 86464
    }
  }
  """
  def get_last_buses_map(bus_stop_no) do
    %Postgrex.Result{rows: rows} = Buses.get_last_bus_by_service_by_bus_stop(bus_stop_no)

    rows
    |> Enum.reduce(%{}, fn [dpi_route_code, dest_code, arriving_time], acc ->
      key = {dpi_route_code, dest_code}

      value = %{
        "time_seconds" => arriving_time,
        "time_iso" => TimeUtil.get_iso_date_from_seconds(arriving_time)
      }

      Map.put(acc, key, value)
    end)
  end

  def get_sequence_no_map(bus_stop_no) do
    %Postgrex.Result{rows: rows} = Buses.get_sequence_no_by_service_by_stop(bus_stop_no)

    rows
    |> Enum.reduce(%{}, fn [dpi_route_code, line_no, direction, visit_no, sequence_no], acc ->
      visit_no = Integer.to_string(visit_no)

      service_no =
        case is_nil(dpi_route_code) do
          true -> line_no |> Integer.to_string()
          _ -> dpi_route_code
        end

      key = {service_no, direction, visit_no}

      value = Map.put(acc, key, sequence_no)
    end)
  end

  # TODO: Query with BaseVersion, OperatingDay
  def get_last_bus_by_service_by_bus_stop(bus_stop_no) do
    query = "
    select distinct on (dpi_route_code) dpi_route_code, dest_code, arriving_time
      from pids_schedule s
      inner join pids_base_version b on s.base_version = b.base_version
      where s.point_no=#{bus_stop_no} and b.status = 'live'
      order by dpi_route_code, arriving_time desc;
    "
    SQL.query!(Repo, query, [])
  end

  def get_sequence_no_by_service_by_stop(bus_stop_no) do
    query = "
    select distinct on (dpi_route_code, line_no, direction, visit_no) dpi_route_code, line_no, direction, visit_no, sequence_no
    from pids_schedule s
    inner join pids_base_version b on s.base_version = b.base_version
    where s.point_no=#{bus_stop_no} and b.status = 'live'
    order by dpi_route_code desc
    "
    SQL.query!(Repo, query, [])
  end

  # TODO: Query with BaseVersion
  def get_all_services_by_bus_stop(bus_stop_no) do
    query = "
    select distinct dpi_route_code, dest_code from pids_schedule s
    inner join pids_base_version b on s.base_version = b.base_version
    where s.point_no=#{bus_stop_no} and b.status = 'live'
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

  def get_realtime_quickest_way_to_by_bus_stop(bus_stop_no) do
    query = "
    select distinct on(poi_cd_txt, poi_stop_num, svc_txt, direction_num, visit_no_num) poi_cd_txt, poi_stop_num, svc_txt, direction_num, visit_no_num, tm_taken_num from
      (select psm.poi_cd_txt, qwt_poi.poi_stop_num, qwt_poi.svc_txt, qwt_poi.direction_num, qwt_poi.visit_no_num, qwt_poi.tm_taken_num
      FROM pids_quickest_way_to_poi qwt_poi
      inner join pids_poi_stops_map psm
      on psm.pt_no_num = poi_stop_num
      where depart_stop_num=#{bus_stop_no}
      group by psm.poi_cd_txt, qwt_poi.poi_stop_num, qwt_poi.svc_txt, qwt_poi.direction_num, qwt_poi.visit_no_num, qwt_poi.tm_taken_num
      order by psm.poi_cd_txt, qwt_poi.poi_stop_num, qwt_poi.svc_txt, qwt_poi.direction_num, qwt_poi.visit_no_num, tm_taken_num) r
    order by poi_cd_txt, poi_stop_num, svc_txt, direction_num, visit_no_num, tm_taken_num
    "
    SQL.query!(Repo, query, [])
  end
end
