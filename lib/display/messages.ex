# Display.Messages.get_messages("pid0132")
# Display.Messages.get_messages("pid0001")
defmodule Display.Messages do
  @moduledoc false

  import Ecto.Query, warn: false
  alias Display.Repo

  alias Display.Messages.{MessageAssignment, MessageData}

  alias Display.Utils.TimeUtil

  @high_priority_min_value 100

  def get_messages(nil), do: nil

  def get_messages(panel_id) do
    # get scheduled and adhoc messages from db

    tasks = [
      Task.async(fn -> get_messages_option1(panel_id) end),
      Task.async(fn -> get_messages_option2(panel_id) end)
    ]

    Task.yield_many(tasks)
    |> Enum.reduce([], fn {task, result}, acc ->
      case result do
        nil ->
          Task.shutdown(task, :brutal_kill)
          exit(:timeout)

        {:exit, reason} ->
          exit(reason)

        {:ok, []} ->
          acc

        {:ok, result} ->
          acc ++ [result |> Enum.at(0)]
      end
    end)
  end

  defp get_messages_option1(nil), do: nil

  # These messages have only start date and end date
  defp get_messages_option1(panel_id) do
    now = TimeUtil.get_time_now()

    from(cmd in MessageData,
      join: cma in MessageAssignment,
      on: cma.message_data_id == cmd.message_data_id,
      where:
        cma.bus_stop_panel_id == ^panel_id and
          cmd.start_date_time <= ^now and cmd.end_date_time >= ^now,
      select: %{
        type: cmd.type,
        priority: cmd.priority,
        message_content: cmd.message_content,
        day_type_1: cmd.day_type_1,
        day_type_2: cmd.day_type_2,
        day_type_3: cmd.day_type_3,
        start_date_time: cmd.start_date_time,
        end_date_time: cmd.end_date_time,
        start_time_1: cmd.start_time_1,
        end_time_1: cmd.end_time_1
      }
    )
    |> Repo.all()
  end

  defp get_messages_option2(nil), do: nil

  # These messages have start time and end time to show on weekdays, saturday and sunday - public holidays
  defp get_messages_option2(panel_id) do
    current_time = TimeUtil.get_current_time()

    from(cmd in MessageData,
      join: cma in MessageAssignment,
      on: cma.message_data_id == cmd.message_data_id,
      where:
        cma.bus_stop_panel_id == ^panel_id and
          cmd.start_time_1 <= ^current_time and
          cmd.end_time_1 >= ^current_time,
      select: %{
        type: cmd.type,
        priority: cmd.priority,
        message_content: cmd.message_content,
        day_type_1: cmd.day_type_1,
        day_type_2: cmd.day_type_2,
        day_type_3: cmd.day_type_3,
        start_date_time: cmd.start_date_time,
        end_date_time: cmd.end_date_time,
        start_time_1: cmd.start_time_1,
        end_time_1: cmd.end_time_1
      }
    )
    |> Repo.all()
    |> filter_messages_on_day_types()
  end

  defp filter_messages_on_day_types(messages) do
    now = TimeUtil.get_time_now()
    day_of_week_no = now |> TimeUtil.get_weekday_no()
    day_of_week_name = now |> TimeUtil.get_weekday_name()

    is_today_public_holiday = TimeUtil.get_today_date_string() |> TimeUtil.is_public_holiday?()

    messages
    |> Enum.filter(fn m ->
      (m.day_type_1 == true and day_of_week_name == "Sunday") or
        (m.day_type_1 == true and is_today_public_holiday) or
        (m.day_type_2 == true and day_of_week_name == "Saturday") or
        (m.day_type_3 == true and day_of_week_no >= 1 and day_of_week_no <= 5) or
        (m.day_type_1 != true and m.day_type_2 != true and m.day_type_3 != true)
    end)
  end

  def get_message_timings([], _cycle_time) do
    %{
      message_map: nil,
      timeline: nil
    }
  end

  def get_message_timings(_messages, nil) do
    %{
      message_map: nil,
      timeline: nil
    }
  end

  # Eg:
  # Input:
  #     cycle_time = 300
  #     messages = [
  #       %{
  #         text: "message 1",
  #         pm: 12
  #       },
  #       %{
  #         text: "message 2",
  #         pm: 30
  #       },
  #       %{
  #         text: "message 3",
  #         pm: 40
  #       }
  #     ]
  # Output: %{
  #   message_map: %{0 => "message 1", 1 => "message 2", 2 => "message 3"},
  #   timeline: [
  #     {0, 0},
  #     {30, 1},
  #     {60, 2},
  #     {90, 0},
  #     {96, 1},
  #     {126, 2},
  #     {156, 1},
  #     {186, 2},
  #     {216, 2},
  #     %{246 => nil}
  #   ]
  # }
  def get_message_timings(messages, cycle_time) do
    # messages = @messages
    # cycle_time = @cycle_time

    # if there are high priority messages, exclude standard priority message
    messages = discard_standard_priority_messages_maybe(messages)

    # mmdt 2% of cycle time, Eg: 6s
    minimum_message_display_time = cycle_time * 0.02
    # lmdt 10% of cycle time, Eg: 30s
    longest_message_display_time = cycle_time * 0.10

    # Eg: 82
    sum_of_pms = Enum.reduce(messages, 0, &(&1.pm + &2))

    # Eg: 100
    total_message_percentage_time = max(100, sum_of_pms)

    # Maximum no of slots in a group slot aka max_continuos_slots, Eg: 5
    max_continuos_slots = (longest_message_display_time / minimum_message_display_time) |> ceil

    # Eg: %{0 => "message 1", 1 => "message 2", 2 => "message 3"}
    message_map = create_message_map(messages)

    messages
    |> create_group_slot_list(
      cycle_time,
      minimum_message_display_time,
      total_message_percentage_time,
      max_continuos_slots
    )
    |> determine_sequence_of_messages(messages)
    |> create_timeline_from_sequence(minimum_message_display_time)
    |> add_empty_slot_in_timeline_maybe(sum_of_pms)
    |> create_timeline_message_map(message_map)
  end

  defp discard_standard_priority_messages_maybe(messages) do
    if has_higher_priority_messages?(messages),
      do: filter_high_priority_messages(messages),
      else: messages
  end

  defp has_higher_priority_messages?(messages) do
    Enum.any?(messages, &(&1.pm >= @high_priority_min_value))
  end

  defp filter_high_priority_messages(messages) do
    Enum.filter(messages, &(&1.pm >= @high_priority_min_value))
  end

  # Output: %{0 => "message 1", 1 => "message 2", 2 => "message 3"},
  defp create_message_map(messages) do
    messages
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {message, index}, acc ->
      Map.put(acc, index, message.text)
    end)
  end

  # Determine smallest slots(no_of_mmdt_slots) for each message and then group these smallest slots
  # Output: [
  #   [[0, 0, 0, 0, 0], [0]],
  #   [[1, 1, 1, 1, 1], [1, 1, 1, 1, 1], [1, 1, 1, 1, 1]]
  #   [[2, 2, 2, 2, 2], [2, 2, 2, 2, 2], [2, 2, 2, 2, 2], [2, 2, 2, 2, 2]]
  # ]
  defp create_group_slot_list(
         messages,
         cycle_time,
         minimum_message_display_time,
         total_message_percentage_time,
         max_continuos_slots
       ) do
    messages
    |> Enum.with_index()
    |> Enum.map(fn {message, index} ->
      message_display_time = message.pm * (cycle_time / total_message_percentage_time)
      message_display_time = max(message_display_time, minimum_message_display_time) |> ceil
      # no_of_mmdt_slots aka no of slots
      # One slot is 2% of cycle time
      no_of_mmdt_slots = (message_display_time / minimum_message_display_time) |> ceil

      # Group no_of_mmdt_slots
      # Note: Maximum no of slots aka max_continuos_slots, in a grouped slot is always 5
      # Eg: no_of_mmdt_slots of 0th message in messages is 6, then grouped_slots is [[0, 0, 0, 0, 0], [0]]
      1..no_of_mmdt_slots
      |> Enum.map(fn _ -> index end)
      |> Enum.chunk_every(max_continuos_slots)
    end)
  end

  # Output: [
  #   [0, 0, 0, 0, 0],
  #   [1, 1, 1, 1, 1],
  #   [2, 2, 2, 2, 2],
  #   [0],
  #   [1, 1, 1, 1, 1],
  #   [2, 2, 2, 2, 2],
  #   [1, 1, 1, 1, 1],
  #   [2, 2, 2, 2, 2],
  #   [2, 2, 2, 2, 2]
  # ]
  defp determine_sequence_of_messages(grouped_slots_list, messages) do
    max_no_of_grouped_slots = grouped_slots_list |> List.last() |> length()

    for index <- 0..max_no_of_grouped_slots do
      for {_, message_index} <- Enum.with_index(messages) do
        current_message = Enum.at(grouped_slots_list, message_index)
        Enum.at(current_message, index)
      end
    end
    |> List.foldr([], &(&1 ++ &2))
    |> Enum.filter(fn x -> is_nil(x) |> Kernel.not() end)
  end

  # Output: %{
  #   time_elapsed: 246,
  #   timeline: [
  #     {0, 0},
  #     {30, 1},
  #     {60, 2},
  #     {90, 0},
  #     {96, 1},
  #     {126, 2},
  #     {156, 1},
  #     {186, 2},
  #     {216, 2}
  #   ]
  # }
  #
  # Note: Each element in the timeline represents {time_in_seconds, index_of_messages}
  #       For eg, {30, 0} means at 30 seconds show 1st(index 0) message in the messages list
  defp create_timeline_from_sequence(sequence_of_messages, minimum_message_display_time) do
    Enum.reduce(sequence_of_messages, %{timeline: [], time_elapsed: 0}, fn grouped_slot, acc ->
      time = acc.time_elapsed
      [head | _] = grouped_slot
      time_elapsed = (length(grouped_slot) * minimum_message_display_time) |> floor

      acc
      |> update_in([:timeline], &Enum.concat(&1, [{time, head}]))
      |> update_in([:time_elapsed], &sum(&1, time_elapsed))
    end)
  end

  # Output: %{
  #   time_elapsed: 246,
  #   timeline: [
  #     {0, 0},
  #     {30, 1},
  #     {60, 2},
  #     {90, 0},
  #     {96, 1},
  #     {126, 2},
  #     {156, 1},
  #     {186, 2},
  #     {216, 2},
  #     %{246 => nil}
  #   ]
  # }
  defp add_empty_slot_in_timeline_maybe(timeline, sum_of_pms) do
    if sum_of_pms < 100,
      do:
        update_in(
          timeline,
          [:timeline],
          &Enum.concat(&1, [{timeline.time_elapsed, nil}])
        ),
      else: timeline
  end

  # Output: %{
  #   message_map: %{0 => "message 1", 1 => "message 2", 2 => "message 3"},
  #   timeline: [
  #     {0, 0},
  #     {30, 1},
  #     {60, 2},
  #     {90, 0},
  #     {96, 1},
  #     {126, 2},
  #     {156, 1},
  #     {186, 2},
  #     {216, 2},
  #     %{246 => nil}
  #   ]
  # }
  defp create_timeline_message_map(timeline, message_map) do
    timeline
    |> put_in([:message_map], message_map)
    |> pop_in([:time_elapsed])
    |> elem(1)
  end

  defp sum(a, b) do
    a + b
  end

  def get_suppressed_messages(nil) do
    %{all_services: nil, few_services: nil}
  end

  def get_suppressed_messages(_bus_stop_no) do
    %{
      all_services: nil,
      few_services: %{
        "51" => "Not operating today",
        "40" => "Last bus departed"
      }
    }
  end

  # def get_suppressed_messages(_bus_stop_no) do
  #   %{
  #     all_services: %{message: "No buses will stop here today due to F1 road closure"},
  #     few_services: nil
  #   }
  # end
end
