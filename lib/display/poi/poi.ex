defmodule Display.Poi.Poi do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "poi" do
    field :code, :string, primary_key: true
    field :name, :string
    field :type, :string
    field :rank, :integer
    field :pictogram_url, :string
    field :effective_date, :utc_datetime

    timestamps()
  end

  @field [
    :code,
    :name,
    :type,
    :rank,
    :pictogram_url,
    :effective_date
  ]
  def changeset(poi, params \\ %{}) do
    cast(poi, params, @field)
  end
end
