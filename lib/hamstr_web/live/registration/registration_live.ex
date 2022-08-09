defmodule HamstrWeb.RegistrationLive do
  use HamstrWeb, :live_view

  alias Hamstr.Accounts
  alias Hamstr.Accounts.User
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    user = %User{}

    socket =
      socket
      |> assign(user: user)
      |> assign(changeset: Accounts.change_user_registration(user))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign(changeset: changeset)

    {:noreply, socket}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    socket = case Accounts.register_user(user_params) do
      {:ok, user} ->
        socket
        |> put_flash(:info, "User created successfully.")
        |> tap(fn _ -> PubSub.broadcast!(Hamstr.PubSub, "new-registration", {:new_user, user}) end)
        |> redirect(to: Routes.user_session_path(HamstrWeb.Endpoint, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        changeset = Map.put(changeset, :action, :validate)
        assign(socket, changeset: changeset)
    end

    {:noreply, socket}
  end
end
