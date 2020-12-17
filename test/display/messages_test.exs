defmodule DisplayWeb.DisplayTest do
  use DisplayWeb.ConnCase

  alias Display.Messages

  @messages_total_pm_below_100 [
    %{
      text: "message 1",
      pm: 10
    },
    %{
      text: "message 2",
      pm: 20
    },
    %{
      text: "message 3",
      pm: 30
    }
  ]

  @messages_total_pm_above_100 [
    %{
      text: "message 1",
      pm: 40
    },
    %{
      text: "message 2",
      pm: 40
    },
    %{
      text: "message 3",
      pm: 30
    }
  ]

  @messages_with_high_priority_and_standard_priority [
    %{
      text: "message 1",
      pm: 40
    },
    %{
      text: "message 2",
      pm: 100
    },
    %{
      text: "message 3",
      pm: 200
    }
  ]

  @cycle_time 10

  describe "get_message_timings" do
    test "total_pm_below_100" do
      result = Messages.get_message_timings(@messages_total_pm_below_100, @cycle_time)

      assert result == %{
               message_map: %{0 => "message 1", 1 => "message 2", 2 => "message 3"},
               timeline: [{0, 0}, {1, 1}, {2, 2}, {3, 1}, {4, 2}, {5, 2}, {6, nil}]
             }
    end

    test "total_pm_more_than_100" do
      result = Messages.get_message_timings(@messages_total_pm_above_100, @cycle_time)

      assert result == %{
               message_map: %{0 => "message 1", 1 => "message 2", 2 => "message 3"},
               timeline: [
                 {0, 0},
                 {1, 1},
                 {2, 2},
                 {3, 0},
                 {4, 1},
                 {5, 2},
                 {6, 0},
                 {7, 1},
                 {8, 2},
                 {9, 0},
                 {10, 1}
               ]
             }
    end

    test "messages_with_high_priority_and_standard_priority" do
      result =
        Messages.get_message_timings(
          @messages_with_high_priority_and_standard_priority,
          @cycle_time
        )

      assert result == %{
               message_map: %{0 => "message 2", 1 => "message 3"},
               timeline: [
                 {0, 0},
                 {1, 1},
                 {2, 0},
                 {3, 1},
                 {4, 0},
                 {5, 1},
                 {6, 0},
                 {7, 1},
                 {8, 1},
                 {9, 1},
                 {10, 1}
               ]
             }
    end
  end
end
