defmodule Display.Repo.Migrations.CreatePidsPredictionErrorLogs do
  use Ecto.Migration

  def change do
    create table(:pids_prediction_error_logs, primary_key: false) do
      add :id_uuid, :uuid, primary_key: true, null: false
      add :src_txt, :string
      add :src_typ_txt, :string
      add :rsn_txt, :string

      timestamps()
    end
  end
end
