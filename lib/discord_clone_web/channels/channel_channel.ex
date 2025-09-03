defmodule DiscordCloneWeb.ChannelChannel do
  use DiscordCloneWeb, :channel

  alias DiscordClone.Messages
  alias DiscordClone.Servers

  @impl true
  def join("channel:" <> channel_id, _payload, socket) do
    current_user = socket.assigns.current_user
    
    if current_user do
      try do
        channel = Servers.get_channel!(channel_id)
        
        # Check if user is a member of the server
        if Servers.is_server_member?(channel.server_id, current_user.id) do
          # Load recent messages for this channel
          messages = Messages.list_messages_for_channel(channel.id)
          
          socket = 
            socket
            |> assign(:channel, channel)
            |> assign(:channel_id, channel.id)
          
          {:ok, %{messages: format_messages(messages)}, socket}
        else
          {:error, %{reason: "unauthorized"}}
        end
      rescue
        Ecto.NoResultsError ->
          {:error, %{reason: "channel not found"}}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("new_message", %{"content" => content}, socket) do
    current_user = socket.assigns.current_user
    channel_id = socket.assigns.channel_id

    case Messages.create_message(%{
      content: content,
      user_id: current_user.id,
      channel_id: channel_id
    }) do
      {:ok, message} ->
        broadcast(socket, "new_message", format_message(message))
        {:reply, :ok, socket}
      
      {:error, changeset} ->
        {:reply, {:error, %{errors: format_changeset_errors(changeset)}}, socket}
    end
  end

  @impl true
  def handle_in("typing", _payload, socket) do
    current_user = socket.assigns.current_user
    
    broadcast_from(socket, "user_typing", %{
      user_id: current_user.id,
      username: current_user.username
    })
    
    {:noreply, socket}
  end

  defp format_messages(messages) do
    Enum.map(messages, &format_message/1)
  end

  defp format_message(message) do
    %{
      id: message.id,
      content: message.content,
      user: %{
        id: message.user.id,
        username: message.user.username
      },
      inserted_at: message.inserted_at
    }
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end