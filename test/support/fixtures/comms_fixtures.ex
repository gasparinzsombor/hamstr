defmodule Hamstr.CommsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hamstr.Comms` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        content: "some content"
      })
      |> Hamstr.Comms.create_message()

    message
  end
end
