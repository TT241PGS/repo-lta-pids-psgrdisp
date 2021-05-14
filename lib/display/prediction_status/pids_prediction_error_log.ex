defmodule Display.PredictionStatus.PidsPredictionErrorLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key{:id, Ecto.UUID, autogenerate: true}

  schema "pids_prediction_error_logs" do
    field :reason, :string
    field :source, :string
    field :source_type, :string

    timestamps()
  end

  @doc false
  def changeset(pids_prediction_error_log, attrs) do
    pids_prediction_error_log
    |> cast(attrs, [:source, :source_type, :reason])
    |> validate_required([:source, :source_type, :reason])
  end
end
