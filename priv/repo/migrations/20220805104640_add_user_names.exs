defmodule Hamstr.Repo.Migrations.AddUserNames do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :firstname, :string
      add :lastname, :string
    end
  end
end
