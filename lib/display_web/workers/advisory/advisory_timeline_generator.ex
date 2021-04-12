defmodule AdvisoryTimelineGenerator do
  @doc """
    1. Creates timeline if the messages or cycle_time change
    2. Send new_timeline advisory_timeline_player_PANEL_ID

  """
  use GenServer, restart: :transient

  def start_link(panel_id),
    do: GenServer.start_link(__MODULE__, panel_id, name: process_name(panel_id))

  defp process_name(panel_id),
    do: {:via, Registry, {AdvisoryRegistry, "advisory_timeline_generator_#{panel_id}"}}

  def init(panel_id) do
    state = %{
      panel_id: panel_id,
      messages: nil,
      timings: %{
        message_map: nil,
        timeline: nil,
        cycle_time: nil
      },
      cycle_time: nil
    }

    {:ok, state}
  end

  # When new messages arrive, generate new timeline
  def handle_cast(
        {:messages, new_messages},
        %{cycle_time: cycle_time} = state
      ) do
    state = generate_new_timeline(new_messages, cycle_time, state)

    {:noreply, state}
  end

  # When new cycle_time arrives, generate new timeline
  def handle_cast(
        {:cycle_time, new_cycle_time},
        %{messages: messages} = state
      ) do
    state = generate_new_timeline(messages, new_cycle_time, state)

    {:noreply, state}
  end

  defp get_messages(panel_id, cycle_time) do
    %{
      message_map: message_map,
      timeline: timeline
    } =
      Display.Messages.get_all_messages(panel_id)
      |> Display.Messages.get_message_timings(cycle_time)

    GenServer.call(
      "advisory_timeline_player_#{panel_id}",
      {:new_timeline, timeline, message_map}
    )
  end

  # Generate new timeline and push it to timeline_player
  defp generate_new_timeline(messages, new_cycle_time, state) do
    new_timings = Display.Messages.get_message_timings(messages, new_cycle_time)

    GenServer.cast(
      {:via, Registry, {AdvisoryRegistry, "advisory_timeline_player_#{state.panel_id}"}},
      {:new_timeline, new_timings.timeline, new_timings.message_map, new_timings.cycle_time}
    )

    Map.merge(state, %{messages: messages, timings: new_timings, cycle_time: new_cycle_time})
  end
end
