defmodule DisplayWeb.DisplayLive.Utils do
  def get_message_class_names(panes, current_pane, message) do
    [
      "advisory-content",
      get_in(panes, [
        current_pane,
        "config",
        "#{get_in(message, [:type]) |> String.downcase()}_messages_font",
        "color",
        "label"
      ]),
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

  def get_stop_predictions_realtime_set(prop, service_per_page) do
    case service_per_page do
      "5" -> prop.predictions_realtime_5_per_page
      "7" -> prop.predictions_realtime_7_per_page
      "10" -> prop.predictions_realtime_10_per_page
      "14" -> prop.predictions_realtime_14_per_page
      _ -> []
    end
  end

  def get_stop_predictions_scheduled_set(prop, service_per_page) do
    case service_per_page do
      "5" -> prop.predictions_scheduled_5_per_page
      "7" -> prop.predictions_scheduled_7_per_page
      "10" -> prop.predictions_scheduled_10_per_page
      "14" -> prop.predictions_scheduled_14_per_page
      _ -> []
    end
  end

  def get_realtime_active_index(prop, service_per_page) do
    case service_per_page do
      "5" -> prop.predictions_realtime_5_per_page_index
      "7" -> prop.predictions_realtime_7_per_page_index
      "10" -> prop.predictions_realtime_10_per_page_index
      "14" -> prop.predictions_realtime_14_per_page_index
      _ -> nil
    end
  end

  def get_scheduled_active_index(prop, service_per_page) do
    case service_per_page do
      "5" -> prop.predictions_scheduled_5_per_page_index
      "7" -> prop.predictions_scheduled_7_per_page_index
      "10" -> prop.predictions_scheduled_10_per_page_index
      "14" -> prop.predictions_scheduled_14_per_page_index
      _ -> nil
    end
  end

  def pad_bus_stop_no(bus_stop_no) do
    bus_stop_no |> Integer.to_string() |> String.pad_leading(5, "0")
  end

  def animation_duration(message) do
    duration_per_char = 0.25
    duration = String.length(get_in(message, [:text])) * duration_per_char
    "animation-duration: #{duration}s;"
  end
end
