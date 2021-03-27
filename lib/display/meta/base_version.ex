defmodule Display.Meta.BaseVersion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "pids_base_version" do
    field :base_version, :integer, primary_key: true
    field :status, :string

    timestamps(type: :utc_datetime_usec)
  end

  @field [
    :base_version,
    :status
  ]
  def changeset(base_version, params \\ %{}) do
    cast(base_version, params, @field)
  end
end
