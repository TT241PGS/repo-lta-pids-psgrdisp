defmodule AdvisoryTimelinePlayer do
  @doc """
    1. Determines next message to be displayed and triggers at appropriate time
    2. Publish "show_message" event to message:PANEL_ID topic based on timeline schedule - To display message
    2. Publish "show_non_message_template" event to message:PANEL_ID topic based on timeline schedule - To display non message template

  """
  use GenServer, restart: :transient

  require Logger

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

  # When there are no more messages, reset everything
  def handle_cast(
        {:new_timeline, new_timeline, _new_message_map, _cycle_time},
        %{timer_ref: timer_ref, panel_id: panel_id} = state
      )
      when new_timeline == [] or new_timeline == nil do
    # Broadcast Layout Switch message
    DisplayWeb.Endpoint.broadcast!(
      "message:" <> panel_id,
      "show_non_message_template",
      %{}
    )

    reset_timer(timer_ref)
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
          cycle_time: cycle_time,
          panel_id: panel_id
        } = state
      ) do
    {next_message_index, next_trigger_after} =
      get_next_message_tuple(timeline, current_message_index, message_map, cycle_time)

    cond do
      next_message_index != nil and is_list(timeline) and length(timeline) > 0 ->
        message_map_index = Enum.at(timeline, next_message_index) |> elem(1)
        message = get_in(message_map, [message_map_index])

        case message do
          nil ->
            # Broadcast template switch message
            DisplayWeb.Endpoint.broadcast!(
              "message:" <> panel_id,
              "show_non_message_template",
              %{timeline: timeline, message_map: message_map}
            )

          _ ->
            # Broadcast new message
            DisplayWeb.Endpoint.broadcast!(
              "message:" <> panel_id,
              "show_message",
              %{message: message, timeline: timeline, message_map: message_map}
            )
        end

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
