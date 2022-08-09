defmodule HamstrWeb.ConversationLive do
  use HamstrWeb, :live_component

  alias Hamstr.Comms
  alias Hamstr.Comms.Message

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(user: assigns.user)
      |> assign(person: assigns.person)
      |> assign(messages: assigns.messages)
      |> assign_empty_text_input_value()
      |> assign_new_message_changeset()

    {:ok, socket}
  end

  @impl true
  def handle_event("send-new-message", %{"message" => message_args}, socket) do
    socket = case Comms.create_message(message_args) do
      {:ok, message} ->
        send(self(), {:new_message_saved, message})
        assign_empty_text_input_value(socket)

      {:error, _changeset} ->
        socket
    end

    {:noreply, socket}
  end

  def assign_new_message_changeset(socket) do
    changeset = Comms.change_message(%Message{})

    assign(socket, new_message: changeset)
  end

  def assign_empty_text_input_value(socket) do
    assign(socket, text_input_value: "")
  end
end
