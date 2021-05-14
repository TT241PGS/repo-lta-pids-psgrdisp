defmodule Display.Repo.Migrations.CreatePidsPredictionErrorLogs do
  use Ecto.Migration

  def change do
    create table(:pids_prediction_error_logs, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :source, :string
      add :source_type, :string
      add :reason, :string

      timestamps()
    end
  end
end
