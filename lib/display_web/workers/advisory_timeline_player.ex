defmodule AdvisoryTimelinePlayer do
  @doc """
    1. Determines next message to be displayed
    2. Publish message to message:panel_id topic based on timeline schedule - To update message
    2. Publish message to templates:panel_id topic based on timeline schedule - To update template to set A

  """
  use GenServer, restart: :transient

  require Logger

  @minute 60_000

  def start_link(panel_id),
    do: GenServer.start_link(__MODULE__, panel_id, name: process_name(panel_id))

  defp process_name(panel_id),
    do: {:via, Registry, {AdvisoryRegistry, "advisory_timeline_player_#{panel_id}"}}

  def init(panel_id) do
    state = %{
      panel_id: panel_id,
      message_map: nil,
      timeline: nil,
      current_message_index: nil,
      timer_ref: nil
    }

    {:ok, state}
  end

  def handle_cast(
        {:new_timeline, new_timeline, _new_message_map, _cycle_time},
        %{timeline: timeline} = state
      )
      when timeline == new_timeline do
    {:noreply, state}
  end

  def handle_cast(
        {:new_timeline, new_timeline, _new_message_map, _cycle_time},
        state
      )
      when new_timeline == [] or new_timeline == nil do
    state = reset(state)
    {:noreply, reset(state)}
  end

  def handle_cast(
        {:new_timeline, new_timeline, new_message_map, new_cycle_time},
        %{
          current_message_index: current_message_index,
          timer_ref: timer_ref,
          timeline: timeline
        } = state
      )
      when timeline != new_timeline do
    state =
      Map.merge(state, %{
        message_map: new_message_map,
        timeline: new_timeline,
        current_message_index: nil,
        cycle_time: new_cycle_time
      })

    send(self(), :tick)
    {:noreply, state}
  end

  def handle_info(
        :tick,
        %{
          current_message_index: current_message_index,
          timer_ref: timer_ref,
          timeline: timeline,
          message_map: message_map,
          cycle_time: cycle_time
        } = state
      ) do
    {next_message_index, next_trigger_after} =
      get_next_message_tuple(timeline, current_message_index, message_map, cycle_time)

    IO.inspect({next_message_index, next_trigger_after})

    cond do
      next_message_index == nil and is_list(timeline) and length(timeline) > 0 ->
        # Broadcast Layout Switch message
        ""

      next_message_index != nil and is_list(timeline) and length(timeline) > 0 ->
        # Broadcast message
        ""

      true ->
        nil
    end

    # Prepare to trigger next message
    reset_timer(timer_ref)
    timer_ref = set_next_timer({next_message_index, next_trigger_after})

    state =
      Map.merge(state, %{
        current_message_index: next_message_index,
        timer_ref: timer_ref
      })

    {:noreply, state}
  end

  defp get_next_message_tuple(timeline, current_message_index, message_map, nil) do
    {nil, nil}
  end

  defp get_next_message_tuple(timeline, current_message_index, nil, cycle_time) do
    {nil, nil}
  end

  defp get_next_message_tuple(nil, current_message_index, message_map, cycle_time) do
    {nil, nil}
  end

  defp get_next_message_tuple(timeline, current_message_index, message_map, cycle_time)
       when is_list(timeline) and timeline == [] do
    {nil, nil}
  end

  defp get_next_message_tuple(timeline, current_message_index, message_map, cycle_time) do
    cond do
      # If there is only one message, same message has to be shown always after every cycle time seconds
      is_list(timeline) and length(timeline) == 1 ->
        next_message_index = timeline |> List.first() |> elem(1)
        {next_message_index, cycle_time}

      # If current index is nil and timeline exists
      is_nil(current_message_index) ->
        next_message_index = timeline |> List.first() |> elem(1)
        # next_trigger_after will be second next message's time
        next_trigger_after =
          (timeline |> Enum.at(next_message_index + 1) |> elem(0)) -
            (timeline |> Enum.at(next_message_index) |> elem(0))

        {next_message_index, next_trigger_after}

      # If current index is second last index and timeline exists
      current_message_index == length(timeline) - 2 ->
        # next_message_index will be last message
        next_message_index = current_message_index + 1
        # next_trigger_after will be first message's time

        next_trigger_after = cycle_time - (timeline |> Enum.at(next_message_index) |> elem(0))

        {next_message_index, next_trigger_after}

      # If current index is last index and timeline exists
      current_message_index == length(timeline) - 1 ->
        next_message_index = timeline |> List.first() |> elem(1)
        # next_trigger_after will be second next message's time
        next_trigger_after =
          (timeline |> Enum.at(next_message_index + 1) |> elem(0)) -
            (timeline |> Enum.at(next_message_index) |> elem(0))

        {next_message_index, next_trigger_after}

      true ->
        next_message_index = current_message_index + 1
        # next_trigger_after will be second next message's time
        next_trigger_after =
          (timeline |> Enum.at(next_message_index + 1) |> elem(0)) -
            (timeline |> Enum.at(next_message_index) |> elem(0))

        {next_message_index, next_trigger_after}
    end
  end

  defp reset(%{panel_id: panel_id, timer_ref: timer_ref} = state) do
    reset_timer(timer_ref)

    state = %{
      panel_id: panel_id,
      message_map: nil,
      timeline: nil,
      current_message_index: nil,
      timer_ref: nil
    }
  end

  defp reset_timer(nil) do
    nil
  end

  defp reset_timer(timer_ref) do
    Process.cancel_timer(timer_ref)
  end

  defp set_next_timer(nil) do
    nil
  end

  defp set_next_timer(next_trigger_after) when next_trigger_after < 1 do
    Logger.error("Error at set_next_timer, #{next_trigger_after}")
    nil
  end

  defp set_next_timer({next_message_index, next_trigger_after}) do
    Process.send_after(
      self(),
      :tick,
      next_trigger_after * 1000
    )
  end
end
