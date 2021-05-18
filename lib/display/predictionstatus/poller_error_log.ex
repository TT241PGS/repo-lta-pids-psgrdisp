defmodule Display.PredictionStatus.PollerErrorLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id_uuid, Ecto.UUID, autogenerate: true}

  schema "poller_error_logs" do
    field :rsn_txt, :string

    timestamps(inserted_at_source: :crt_dttm, updated_at_source: :upd_dttm)
  end

  @doc false
  def changeset(poller_error_log, attrs) do
    poller_error_log
    |> cast(attrs, [:rsn_txt])
    |> validate_required([:rsn_txt])
  end
end
