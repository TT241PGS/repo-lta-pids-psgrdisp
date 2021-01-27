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
end
