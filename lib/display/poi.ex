defmodule Display.Poi do
  @moduledoc false

  import Ecto.Query, warn: false
  use Timex
  alias Display.Repo
  alias Display.Poi.{Poi, PoiStopsMapping}

  def get_many_destinations_pictogram(dest_codes) when not is_list(dest_codes), do: nil

  def get_many_destinations_pictogram(dest_codes) do
    from(p in Poi,
      join: psm in PoiStopsMapping,
      on: p.code == psm.poi_code,
      where: psm.point_no in ^dest_codes and not is_nil(p.pictogram_url),
      select: %{
        pictograms: p.pictogram_url,
        dest_code: psm.point_no
      }
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn %{pictograms: pictograms, dest_code: dest_code}, acc ->
      update_in(acc, [dest_code], fn _ ->
        pictograms
        |> String.split(",")
        |> Enum.map(fn url ->
          Application.get_env(:display, :multimedia_base_url) <> String.trim(url)
        end)
      end)
    end)
  end

  def get_poi_metadata_map(poi_list) do
    from(p in Poi,
      join: psm in PoiStopsMapping,
      on: p.code == psm.poi_code,
      where: psm.point_no in ^poi_list,
      select: %{
        stop_code: psm.point_no,
        poi_name: p.name,
        pictograms: p.pictogram_url
      }
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn poi, acc ->
      pictograms =
        case is_bitstring(poi.pictograms) do
          true ->
            poi.pictograms
            |> String.split(",")
            |> Enum.map(fn url ->
              Application.get_env(:display, :multimedia_base_url) <> String.trim(url)
            end)

          false ->
            []
        end

      Map.put(acc, poi.stop_code, %{
        "poi_name" => poi.poi_name,
        "pictograms" => pictograms
      })
    end)
  end
end
