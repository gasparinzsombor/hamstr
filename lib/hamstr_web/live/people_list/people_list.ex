defmodule HamstrWeb.PeopleList do
  use HamstrWeb, :live_component

  alias Hamstr.Accounts.User

  def update(assigns, socket) do
    socket =
      socket
      |> assign(people: assigns.people)

    {:ok, socket}
  end
end
