defmodule Display.Buses.BusStop do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "stop" do
    field :point_no, :integer
    field :point_desc, :string
  end

  @doc false
  def changeset(stop, attrs) do
    stop
    |> cast(attrs, [
      :point_no,
      :point_desc
    ])
    |> validate_required([
      :point_no,
      :point_desc
    ])
  end
end
