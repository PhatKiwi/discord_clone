defmodule DiscordClone.ServersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DiscordClone.Servers` context.
  """

  import DiscordClone.AccountsFixtures

  @doc """
  Generate a server.
  """
  def server_fixture(attrs \\ %{}) do
    user = attrs[:user] || user_fixture()
    
    {:ok, server} =
      attrs
      |> Enum.into(%{
        name: "Test Server #{System.unique_integer()}",
        user_id: user.id
      })
      |> DiscordClone.Servers.create_server()

    server
  end

  @doc """
  Generate a server_user.
  """
  def server_user_fixture(attrs \\ %{}) do
    user = attrs[:user] || user_fixture()
    server = attrs[:server] || server_fixture(%{user: user_fixture()})
    role = attrs[:role] || "member"
    
    {:ok, server_user} = DiscordClone.Servers.add_user_to_server(server.id, user.id, role)
    server_user
  end
end