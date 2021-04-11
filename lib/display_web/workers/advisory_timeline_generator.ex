defmodule AdvisoryTimelineGenerator do
  @doc """
    1. Creates timeline if the messages or cycle_time change
    2. Send new_timeline and new_message_map to advisory_timeline_player_PANEL_ID

  """
  use GenServer, restart: :transient

  @minute 60_000

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

  def handle_cast(
        {:messages, new_messages},
        %{messages: messages, timings: timings, cycle_time: cycle_time} = state
      )
      when new_messages == messages and timings.cycle_time == cycle_time do
    {:noreply, state}
  end

  def handle_cast(
        {:messages, new_messages},
        %{messages: messages, timings: timings, cycle_time: nil} = state
      )
      when new_messages != messages do
    IO.inspect(Map.merge(state, %{messages: new_messages}))
    {:noreply, Map.merge(state, %{messages: new_messages})}
  end

  def handle_cast(
        {:messages, new_messages},
        %{messages: messages, timings: timings, cycle_time: cycle_time} = state
      )
      when new_messages != messages or timings.cycle_time != cycle_time do
    new_timings =
      Map.merge(Display.Messages.get_message_timings(new_messages, cycle_time), %{
        cycle_time: cycle_time
      })

    GenServer.cast(
      {:via, Registry, {AdvisoryRegistry, "advisory_timeline_player_#{state.panel_id}"}},
      {:new_timeline, new_timings.timeline, new_timings.message_map, cycle_time}
    )

    IO.inspect(new_timings)

    state =
      Map.merge(state, %{messages: new_messages, timings: new_timings, cycle_time: cycle_time})

    {:noreply, state}
  end

  def handle_cast({:messages, new_messages}, %{messages: messages} = state)
      when new_messages == messages do
    {:noreply, state}
  end

  def handle_cast(
        {:cycle_time, new_cycle_time},
        %{messages: messages, cycle_time: cycle_time} = state
      )
      when new_cycle_time == cycle_time do
    {:noreply, state}
  end

  def handle_cast(
        {:cycle_time, new_cycle_time},
        %{messages: messages, cycle_time: cycle_time} = state
      )
      when new_cycle_time != cycle_time do
    IO.inspect(new_cycle_time)
    IO.inspect(Map.merge(state, %{cycle_time: new_cycle_time}))
    {:noreply, Map.merge(state, %{cycle_time: new_cycle_time})}
  end

  defp schedule_work() do
    # Poll messages every minute
    Process.send_after(self(), :work, @minute)
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
end
