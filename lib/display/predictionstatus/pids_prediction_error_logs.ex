defmodule Display.PredictionStatus.PidsPredictionErrorLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id_uuid, Ecto.UUID, autogenerate: true}

  schema "pids_prediction_error_logs" do
    field :rsn_txt, :string
    field :src_txt, :string
    field :src_typ_txt, :string

    timestamps(inserted_at_source: :crt_dttm, updated_at_source: :upd_dttm)
  end

  @doc false
  def changeset(pids_prediction_error_log, attrs) do
    pids_prediction_error_log
    |> cast(attrs, [:src_txt, :src_typ_txt, :rsn_txt])
    |> validate_required([:src_txt, :src_typ_txt, :rsn_txt])
  end
end
