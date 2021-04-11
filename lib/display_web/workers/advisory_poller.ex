defmodule AdvisoryPoller do
  @doc """
  Polls messages of a particular panel_id every minute
  """
  use GenServer, restart: :transient

  @minute 60_000

  def start_link(panel_id),
    do: GenServer.start_link(__MODULE__, panel_id, name: process_name(panel_id))

  defp process_name(panel_id),
    do: {:via, Registry, {AdvisoryRegistry, "advisory_poller_#{panel_id}"}}

  def init(panel_id) do
    state = %{
      panel_id: panel_id,
      messages: []
    }

    {:ok, state, {:continue, :get_messages}}
  end

  def handle_continue(:get_messages, %{panel_id: panel_id}) do
    messages = get_messages(panel_id)
    schedule_work()

    state = %{
      panel_id: panel_id,
      messages: messages
    }

    {:noreply, state}
  end

  def handle_info(:work, %{panel_id: panel_id} = state) do
    messages = get_messages(panel_id)
    # Reschedule once more
    schedule_work()
    {:noreply, Map.merge(state, %{messages: messages})}
  end

  defp schedule_work() do
    # Poll messages every minute
    Process.send_after(self(), :work, @minute)
  end

  defp get_messages(panel_id) do
    messages = Display.Messages.get_all_messages(panel_id)
    # Inform advisory_timeline_generator that you have received new messages

    GenServer.cast(
      {:via, Registry, {AdvisoryRegistry, "advisory_timeline_generator_#{panel_id}"}},
      {:messages, messages}
    )

    GenServer.cast(
      {:via, Registry, {AdvisoryRegistry, "advisory_timeline_generator_#{panel_id}"}},
      {:cycle_time, 10}
    )
  end
end
