defmodule Hamstr.Comms.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias Hamstr.Accounts.User

  schema "messages" do
    field :content, :string
    belongs_to :sender, User
    belongs_to :receiver, User


    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :sender_id, :receiver_id])
    |> validate_required([:content, :sender_id, :receiver_id])
  end

end
