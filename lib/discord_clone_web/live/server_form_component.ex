defmodule DiscordCloneWeb.ServerFormComponent do
  use DiscordCloneWeb, :live_component

  alias DiscordClone.Servers

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-md w-full mx-4 p-6">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-xl font-semibold text-gray-900 dark:text-white">Create New Server</h2>
          <button
            phx-click="cancel"
            phx-target={@myself}
            class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
          >
            <.icon name="hero-x-mark" class="h-6 w-6" />
          </button>
        </div>

        <.simple_form for={@form} phx-submit="save" phx-target={@myself} phx-change="validate">
          <.input field={@form[:name]} type="text" label="Server Name" placeholder="Enter server name" required />
          
          <:actions>
            <.button type="button" phx-click="cancel" phx-target={@myself} class="mr-2 bg-gray-500 hover:bg-gray-600">
              Cancel
            </.button>
            <.button type="submit" class="bg-indigo-600 hover:bg-indigo-700">
              Create Server
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{server: server} = assigns, socket) do
    changeset = Servers.change_server(server)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"server" => server_params}, socket) do
    changeset =
      socket.assigns.server
      |> Servers.change_server(server_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"server" => server_params}, socket) do
    server_params_with_user = Map.put(server_params, "user_id", socket.assigns.current_user.id)
    case Servers.create_server(server_params_with_user) do
      {:ok, server} ->
        # Notify about server creation
        Phoenix.PubSub.broadcast(
          DiscordClone.PubSub,
          "servers:#{socket.assigns.current_user.id}",
          {:server_created, server}
        )
        
        {:noreply, push_patch(socket, to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.patch)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end