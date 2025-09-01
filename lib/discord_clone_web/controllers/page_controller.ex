defmodule DiscordCloneWeb.PageController do
  use DiscordCloneWeb, :controller

  def home(conn, _params) do
    if conn.assigns[:current_user] do
      # If user is logged in, redirect to servers
      redirect(conn, to: ~p"/servers")
    else
      # If user is not logged in, redirect to login page
      redirect(conn, to: ~p"/users/log_in")
    end
  end
end
