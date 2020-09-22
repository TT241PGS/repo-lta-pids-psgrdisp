# Display.Messages.get_messages("pid0132")
# Display.Messages.get_messages("pid0001")
defmodule Display.Messages do
  @moduledoc false

  import Ecto.Query, warn: false
  alias Display.Repo

  alias Display.Messages.{MessageAssignment, MessageData}

  alias Display.Utils.TimeUtil

  def get_messages(nil), do: nil

  def get_messages(panel_id) do
    # get scheduled and adhoc messages from db

    day_of_week_name =
      TimeUtil.get_time_now()
      |> TimeUtil.get_weekday_name()

    day_of_week_no =
      TimeUtil.get_time_now()
      |> TimeUtil.get_weekday_no()

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
          acc ++ result
      end
    end)
  end

  def get_messages_option1(nil), do: nil

  # These messages have only start date and end date
  def get_messages_option1(panel_id) do
    now = TimeUtil.get_time_now()

    from(cmd in MessageData,
      join: cma in MessageAssignment,
      on: cma.message_data_id == cmd.message_data_id,
      where:
        cma.bus_stop_panel_id == ^panel_id and
          cmd.start_date <= ^now and cmd.end_date >= ^now,
      select: %{
        type: cmd.type,
        priority: cmd.priority,
        message_content: cmd.message_content,
        day_type_1: cmd.day_type_1,
        day_type_2: cmd.day_type_2,
        day_type_3: cmd.day_type_3,
        start_date: cmd.start_date,
        end_date: cmd.end_date,
        start_time_1: cmd.start_time_1,
        end_time_1: cmd.end_time_1,
        start_time_2: cmd.start_time_2,
        end_time_2: cmd.end_time_2
      }
    )
    |> Repo.all()
  end

  def get_messages_option2(nil), do: nil

  # These messages have start time and end time to show on weekdays, saturday and sunday - public holidays
  def get_messages_option2(panel_id) do
    current_time = TimeUtil.get_current_time()

    from(cmd in MessageData,
      join: cma in MessageAssignment,
      on: cma.message_data_id == cmd.message_data_id,
      where:
        cma.bus_stop_panel_id == ^panel_id and
          cmd.start_time_2 <= ^current_time and
          cmd.end_time_2 >= ^current_time,
      select: %{
        type: cmd.type,
        priority: cmd.priority,
        message_content: cmd.message_content,
        day_type_1: cmd.day_type_1,
        day_type_2: cmd.day_type_2,
        day_type_3: cmd.day_type_3,
        start_date: cmd.start_date,
        end_date: cmd.end_date,
        start_time_1: cmd.start_time_1,
        end_time_1: cmd.end_time_1,
        start_time_2: cmd.start_time_2,
        end_time_2: cmd.end_time_2
      }
    )
    |> Repo.all()
    |> filter_messages_on_day_types()
  end

  defp filter_messages_on_day_types(messages) do
    now = TimeUtil.get_time_now()
    day_of_week_no = now |> TimeUtil.get_weekday_no()
    day_of_week_name = now |> TimeUtil.get_weekday_name()

    messages
    |> Enum.filter(fn m ->
      # TODO public holiday check with Sunday
      (m.day_type_1 == true and day_of_week_name == "Sunday") or
        (m.day_type_2 == true and day_of_week_name == "Saturday") or
        (m.day_type_3 == true and day_of_week_no >= 1 and day_of_week_no <= 5) or
        (m.day_type_1 != true and m.day_type_2 != true and m.day_type_3 != true)
    end)
  end
end
