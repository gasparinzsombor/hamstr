defmodule HamstrWeb.IndexLive do
  use HamstrWeb, :live_view

  alias HamstrWeb.IndexLive
  alias Hamstr.Accounts
  alias Hamstr.Comms
  alias Hamstr.Comms.Message
  alias Phoenix.PubSub

  @impl true
  def mount(%{"id" => _id}, session, socket) do
    socket =
      socket
      |> assign_people()
      |> assign_user(session)
      |> subscribe_to_new_user_pubsub()

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    id = Accounts.get_first_user_id()

    path = Routes.live_path(HamstrWeb.Endpoint, IndexLive, id)
    socket = push_redirect(socket, to: path)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    socket =
      socket
      |> assign_selected_person_by_id(id)
      |> subscribe_to_conversation_pubsub()
      |> subscribe_to_flash_message_pubsub()
      |> assign_messages()
      |> push_event("conversation-loaded", %{id: id})

    {:noreply, socket}
  end


  @impl true
  def handle_event("select-person", %{"person-id" => p_id}, socket) do
    {p_id, _} = Integer.parse(p_id)
    people = socket.assigns.people
    selected_person = Enum.find(people, &(&1.id == p_id))

    new_path = Routes.live_path(HamstrWeb.Endpoint, IndexLive, selected_person.id)

    socket =
      socket
      |> assign_selected_person(selected_person)
      |> switch_pubsub_subscription()
      |> assign_messages()
      |> push_patch(to: new_path)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%Message{} = msg, socket) do
    messages = socket.assigns.messages
    messages = [msg | messages]

    socket = assign(socket, messages: messages)

    {:noreply, socket}
  end

  def handle_info({:new_message_saved, message}, socket) do
    PubSub.broadcast(Hamstr.PubSub, get_topic(socket), message)
    PubSub.broadcast(
      Hamstr.PubSub,
      "message-for-#{socket.assigns.selected_person.id}",
      {:new_message_arrived, message}
    )

    {:noreply, socket}
  end

  def handle_info({:new_message_arrived, message}, socket) do
    message = Hamstr.Repo.preload(message, :sender)

    socket =
      socket
      |> maybe_put_new_message_flash(message)

    {:noreply, socket}
  end

  def handle_info({:new_user, user}, socket) do
    people =
      socket.assigns.people
      |> List.insert_at(1, user)
      |> Accounts.sort()

    socket =
      socket
      |> assign(people: people)

    {:noreply, socket}
  end

  def assign_people(socket) do
    socket
    |> assign(people: Accounts.list_all_users())
  end

  def assign_user(socket, session) do
    token = session["user_token"]
    user = Accounts.get_user_by_session_token(token)
    assign(socket, user: user)
  end

  def assign_selected_person_by_id(socket, id) do
    person = Accounts.get_user!(id)

    socket
    |> assign_selected_person(person)
  end

  def assign_selected_person(socket, person \\ nil) do
    people = socket.assigns.people

    person = if person do
      person
    else
      List.first(people)
    end

    socket |> assign(selected_person: person)
  end
  def assign_messages(socket) do
    receiver = socket.assigns.selected_person
    sender = socket.assigns.user
    messages =
      Comms.list_messages_between_people(sender.id, receiver.id)
      |> Enum.reverse()

    socket
    |> assign(messages: messages)
  end

  def subscribe_to_new_user_pubsub(socket) do
    :ok = PubSub.subscribe(Hamstr.PubSub, "new-registration")
    socket
  end


  def subscribe_to_conversation_pubsub(socket) do
    actual_topic = get_topic(socket)
    :ok = PubSub.subscribe(Hamstr.PubSub, actual_topic)

    IO.puts("Subscribed to pubsub with topic: #{actual_topic}")

    assign(socket, actual_topic: actual_topic)
  end

  def subscribe_to_flash_message_pubsub(socket) do
    topic = "message-for-#{socket.assigns.user.id}"

    IO.puts("Subscribed for pubsub with topic #{topic}")

    :ok = PubSub.subscribe(Hamstr.PubSub, topic)

    socket
  end

  def switch_pubsub_subscription(socket) do
    previous_topic = socket.assigns.actual_topic

    :ok = PubSub.unsubscribe(Hamstr.PubSub, previous_topic)
    socket
  end

  def maybe_put_new_message_flash(socket, message) do
    if(message.sender_id != socket.assigns.selected_person.id) do
      socket
      |> put_flash(:info, "New message received from #{Accounts.User.whole_name(message.sender)}")
    else
      socket
    end
  end

  defp get_topic(socket) do
    users = [socket.assigns.user, socket.assigns.selected_person]
    user_ids =
      users
      |> Enum.map(&(&1.id))
      |> Enum.sort()
      |> Enum.join("-")

    "conversation-#{user_ids}"
  end

end
