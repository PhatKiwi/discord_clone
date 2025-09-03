defmodule DiscordCloneWeb.ChatComponent do
  use DiscordCloneWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"chat-#{@id}"} class="flex flex-col h-full" phx-hook="ChatSetup" data-channel-id={@channel.id} data-socket-token={@socket_token}>
      <!-- Channel Header -->
      <div class="p-4 border-b border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
        <div class="flex items-center">
          <.icon name="hero-hashtag" class="h-5 w-5 text-gray-400 mr-2" />
          <h3 class="text-lg font-medium text-gray-900 dark:text-white"><%= @channel.name %></h3>
        </div>
      </div>

      <!-- Messages Area -->
      <div 
        id="messages-container"
        class="flex-1 overflow-y-auto p-4 space-y-4"
      >
        <div id="messages">
          <!-- Messages will be inserted here via WebSocket -->
        </div>
        
        <!-- Typing indicator -->
        <div id="typing-indicator" class="text-sm text-gray-500 dark:text-gray-400" style="display: none;">
          <span id="typing-users"></span>
        </div>
      </div>

      <!-- Message Input -->
      <div class="p-4 bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700">
        <form id="message-form">
          <div class="flex space-x-3">
            <input
              type="text"
              id="message-input"
              placeholder={"Message ##{@channel.name}"}
              class="flex-1 min-w-0 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md 
                     bg-white dark:bg-gray-700 text-gray-900 dark:text-white 
                     placeholder-gray-500 dark:placeholder-gray-400 
                     focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              maxlength="2000"
              autocomplete="off"
            />
            <button
              type="submit"
              class="inline-flex items-center px-4 py-2 border border-transparent rounded-md 
                     bg-indigo-600 hover:bg-indigo-700 text-white font-medium 
                     focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500
                     disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <.icon name="hero-paper-airplane" class="h-4 w-4" />
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end