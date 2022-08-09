defmodule HamstrWeb.Conversation.MessageLive do
  use HamstrWeb, :live_component


  def make_classes(is_my_message) do
    base = "message"

    user_specific = if is_my_message do
      "user-message"
    else
      "partner-message"
    end

    Enum.join([base, user_specific], " ")
  end
end
