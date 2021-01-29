defmodule Debug do
  @moduledoc false
  use Surface.LiveComponent

  property prop, :map, default: %{}

  def render(assigns) do
    ~H"""
    <div class="debug">
      <section>
        <h2>Schedule/Adhoc messages</h2>
        <section>
          <h3>Cycle Time (seconds)</h3>
          <p class="pl20">{{inspect(@prop.cycle_time)}}</p>
        </section>
        <section>
        <h3>Message Map (msg_index, msg_text)</h3>
        <p :for={{ {k, v} <- (@prop.messages.message_map || [])}}>
          <span class="pl20">{{k}}, {{inspect(v)}} </span>
        </p>
        </section>
        <section>
        <h3>Message Timeline (seconds, msg_index)</h3>
        <p class="pl20">{{inspect(@prop.messages.timeline)}}</p>
        </section>
      </section>
      <section>
        <h2>Suppressed Messages</h2>
        <p>{{inspect(@prop.suppressed_messages)}}</p>
      </section>
      <section>
        <h2>Layout Mode</h2>
        <p>{{inspect(@prop.layout_mode)}}</p>
      </section>
    </div>
    """
  end
end
