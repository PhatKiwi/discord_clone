defmodule DiscordCloneWeb.HeaderComponent do
  @moduledoc """
  Provides the unified app header component.
  """
  use Phoenix.Component
  use DiscordCloneWeb, :verified_routes

  @doc """
  Renders the unified app header with navigation.

  ## Examples

      <.header current_user={@current_user} />
  """
  attr :current_user, :any, default: nil
  attr :class, :string, default: ""

  def header(assigns) do
    ~H"""
    <header class={"px-4 sm:px-6 lg:px-8 #{@class}"}>
      <div class="flex items-center justify-between border-b border-zinc-100 py-3 text-sm">
        <div class="flex items-center gap-4">
          <.link navigate={~p"/"} class="flex items-center gap-2">
            <img src={~p"/images/logo.svg"} width="36" alt="Discord Clone" />
            <span class="font-semibold text-lg text-zinc-900">Discord Clone</span>
          </.link>
        </div>
        
        <nav class="flex items-center gap-4 font-semibold leading-6 text-zinc-900">
          <%= if @current_user do %>
            <.link navigate={~p"/servers"} class="hover:text-zinc-700">
              My Servers
            </.link>
            <div class="flex items-center gap-2 px-3 py-1 bg-zinc-50 rounded-lg">
              <div class="h-6 w-6 rounded-full bg-indigo-600 flex items-center justify-center">
                <span class="text-xs font-medium text-white">
                  <%= String.first(@current_user.username) |> String.upcase() %>
                </span>
              </div>
              <span class="text-sm text-zinc-700"><%= @current_user.username %></span>
            </div>
            <.link navigate={~p"/users/settings"} class="hover:text-zinc-700">
              Settings
            </.link>
            <.link href={~p"/users/log_out"} method="delete" class="text-red-600 hover:text-red-700">
              Log out
            </.link>
          <% else %>
            <.link navigate={~p"/users/log_in"} class="hover:text-zinc-700">
              Log in
            </.link>
            <.link navigate={~p"/users/register"} class="rounded-lg bg-zinc-900 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-zinc-700">
              Register <span aria-hidden="true">→</span>
            </.link>
          <% end %>
        </nav>
      </div>
    </header>
    """
  end
end