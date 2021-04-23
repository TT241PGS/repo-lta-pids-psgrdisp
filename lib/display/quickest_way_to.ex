defmodule Display.QuickestWayTo do
  @moduledoc false

  import Ecto.Query, warn: false
  use Timex
  alias Display.Repo
  alias Display.QuickestWayTo.QuickestWayTo
  alias Display.Utils.TimeUtil

  def get_many_destinations_pictogram(bus_stop_no) when not is_number(bus_stop_no), do: nil

  def get_quickest_way_to_list_by_bus_stop(bus_stop_no) do
    now = TimeUtil.get_time_now()

    from(qwt in QuickestWayTo,
      # The qwt.effective_date in DB is assumed to be in UTC
      where: qwt.bus_stop_code == ^bus_stop_no and qwt.effective_date <= ^now,
      or_where: qwt.bus_stop_code == ^bus_stop_no and is_nil(qwt.effective_date),
      order_by: qwt.sort_order,
      select: %{
        poi_code: qwt.poi_code,
        alternative_poi_display_name: qwt.alternative_poi_display_name,
        alternative_text: qwt.alternative_text,
        alternative_pictogram: qwt.alternative_pictogram,
        effective_date: qwt.effective_date
      }
    )
    |> Repo.all()
  end

  # To add alternate POIs
  # To sort and filter POIs bases on pids_quickest_way_to
  def transform_quickest_way_to(calculated_quickest_way_to_list, bus_stop_no) do
    get_quickest_way_to_list_by_bus_stop(bus_stop_no)
    |> Enum.map(fn qwt ->
      case String.length(qwt.poi_code) > 0 do
        true ->
          Enum.find(calculated_quickest_way_to_list, fn calculated_qwt ->
            calculated_qwt["poi"]["poi_code"] == qwt.poi_code
          end)

        false ->
          alternative_pictograms =
            qwt.alternative_pictogram
            |> Enum.map(fn file_name ->
              Application.get_env(:display, :multimedia_base_url) <> String.trim(file_name)
            end)

          %{
            "poi" => %{
              "pictograms" => alternative_pictograms,
              "poi_name" => qwt.alternative_poi_display_name,
              "poi_message" => qwt.alternative_text
            },
            "type" => "alternate",
            "services" => []
          }
      end
    end)
    |> Enum.filter(fn item -> not is_nil(item) end)
  end
end
