defmodule DisplayWeb.DisplayLive.Utils do
  @dest_code_waypoint_map %{
    02089 => 02099,
    03218 => 03239,
    11389 => 11379,
    22008 => 22009,
    22199 => 22609,
    46008 => 46009,
    46101 => 46069,
    52008 => 52009,
    55231 => 55009,
    59008 => 59009,
    75008 => 75009,
    77008 => 77009,
    84439 => 84299
  }

  @dest_code_dest_name_map %{
    02099 => 02089,
    03239 => 03218,
    11379 => 11389,
    22009 => 22008,
    22609 => 22199,
    46009 => 46008,
    46069 => 46101,
    52009 => 52008,
    55009 => 55231,
    59009 => 59008,
    75009 => 75008,
    77009 => 77008,
    84299 => 84439
  }

  @dest_code_dest_direction_map %{
    02099 => 02089,
    03239 => 03218,
    11379 => 11389,
    22009 => 22008,
    22609 => 22199,
    46009 => 46008,
    46069 => 46101,
    52009 => 52008,
    55009 => 55231,
    59009 => 59008,
    75009 => 75008,
    84299 => 84439
  }

  def get_message_class_names(panes, current_pane, message) do
    [
      "advisory-content",
      get_in(panes, [
        current_pane,
        "config",
        "#{get_in(message, [:type]) |> String.downcase()}_messages_font",
        "style",
        "label"
      ])
    ]
    |> Enum.filter(&is_bitstring/1)
    |> Enum.map(fn text ->
      text
      |> String.trim()
      |> String.split(" ")
      |> Enum.join("-")
      |> String.downcase()
    end)
    |> Enum.join(" ")
  end

  def get_message_style(panes, current_pane, message) do
    color =
      get_in(panes, [
        current_pane,
        "config",
        "#{get_in(message, [:type]) |> String.downcase()}_messages_font",
        "color"
      ])

    case is_bitstring(color) do
      true -> "color: #{color} !important"
      false -> ""
    end
  end

  def get_stop_predictions_realtime_set(prop, service_per_page) do
    case service_per_page do
      "5" -> prop.predictions_realtime_5_per_page
      "6" -> prop.predictions_realtime_6_per_page
      "7" -> prop.predictions_realtime_7_per_page
      "9" -> prop.predictions_realtime_9_per_page
      "10" -> prop.predictions_realtime_10_per_page
      "12" -> prop.predictions_realtime_12_per_page
      "14" -> prop.predictions_realtime_14_per_page
      _ -> []
    end
  end

  def get_stop_predictions_scheduled_set(prop, service_per_page) do
    case service_per_page do
      "5" -> prop.predictions_scheduled_5_per_page
      "6" -> prop.predictions_scheduled_6_per_page
      "7" -> prop.predictions_scheduled_7_per_page
      "9" -> prop.predictions_scheduled_9_per_page
      "10" -> prop.predictions_scheduled_10_per_page
      "12" -> prop.predictions_scheduled_12_per_page
      "14" -> prop.predictions_scheduled_14_per_page
      _ -> []
    end
  end

  def get_realtime_active_index(prop, service_per_page) do
    case service_per_page do
      "5" -> prop.predictions_realtime_5_per_page_index
      "6" -> prop.predictions_realtime_6_per_page_index
      "7" -> prop.predictions_realtime_7_per_page_index
      "9" -> prop.predictions_realtime_9_per_page_index
      "10" -> prop.predictions_realtime_10_per_page_index
      "12" -> prop.predictions_realtime_12_per_page_index
      "14" -> prop.predictions_realtime_14_per_page_index
      _ -> nil
    end
  end

  def get_scheduled_active_index(prop, service_per_page) do
    case service_per_page do
      "5" -> prop.predictions_scheduled_5_per_page_index
      "6" -> prop.predictions_scheduled_6_per_page_index
      "7" -> prop.predictions_scheduled_7_per_page_index
      "9" -> prop.predictions_scheduled_9_per_page_index
      "10" -> prop.predictions_scheduled_10_per_page_index
      "12" -> prop.predictions_scheduled_12_per_page_index
      "14" -> prop.predictions_scheduled_14_per_page_index
      _ -> nil
    end
  end

  def pad_bus_stop_no(bus_stop_no) do
    bus_stop_no |> Integer.to_string() |> String.pad_leading(5, "0")
  end

  def advisories_animation_duration(message) do
    duration_per_char = 0.05
    min_duration = duration_per_char * 90
    duration = String.length(get_in(message, [:text])) * duration_per_char
    "animation-duration: #{max(min_duration, duration)}s;"
  end

  def advisories_animation_end_margin(message) do
    margin_per_char = 1
    margin = String.length(get_in(message, [:text])) * margin_per_char
    "-#{ceil(margin)}%"
  end

  def get_waypoints_length(waypoints) do
    icon_length = 4

    waypoints
    |> Enum.reduce(0, fn waypoint, acc ->
      no_of_pictograms = length(waypoint["pictograms"])
      pictograms_length = no_of_pictograms * icon_length
      acc + String.length(waypoint["text"]) + pictograms_length
    end)
  end

  def swap_dest_code_list(bus_stop_nos) do
    bus_stop_nos =
      bus_stop_nos
      |> Enum.map(fn bus_stop_no ->
        case Map.get(@dest_code_dest_name_map, String.to_integer(bus_stop_no)) do
          nil -> bus_stop_no |> String.to_integer()
          new_no -> new_no
        end
      end)
  end

  def swap_dest_code_waypoint(dest_code) do
    swapped_map = @dest_code_waypoint_map[dest_code]

    case is_nil(swapped_map) do
      true -> dest_code
      false -> swapped_map
    end
  end

  def swap_dest_code_dest_name(dest_code) do
    swapped_map = @dest_code_dest_name_map[dest_code]

    case is_nil(swapped_map) do
      true -> dest_code
      false -> swapped_map
    end
  end

  def swap_dest_code_direction(dest_code) do
    swapped_map = @dest_code_dest_direction_map[dest_code]

    case is_nil(swapped_map) do
      true -> dest_code
      false -> swapped_map
    end
  end

  def get_content_type(current_layout_panes, pane) do
    get_in(current_layout_panes, [pane, "type", "value"])
  end
end
