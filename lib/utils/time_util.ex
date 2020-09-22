defmodule Display.Utils.TimeUtil do
  @moduledoc false

  use Timex

  def get_timezone do
    Timezone.get("Asia/Singapore")
  end

  def get_time_now do
    Timezone.convert(Timex.now(), get_timezone)
  end

  def get_beginning_of_day do
    get_time_now()
    |> Timex.beginning_of_day()
  end

  def get_current_time do
    get_time_now
    |> Timex.format!("%H:%M", :strftime)
  end

  def get_weekday_name(nil), do: nil

  def get_weekday_name(date) do
    date
    |> Timex.weekday()
    |> Timex.day_name()
  end

  def get_weekday_no(nil), do: nil

  def get_weekday_no(date) do
    date
    |> Timex.weekday()
  end
end
