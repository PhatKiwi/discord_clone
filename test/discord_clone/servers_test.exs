defmodule DiscordClone.ServersTest do
  use DiscordClone.DataCase

  alias DiscordClone.Servers
  alias DiscordClone.Servers.Server
  alias DiscordClone.Servers.ServerUser

  describe "servers" do
    import DiscordClone.ServersFixtures
    import DiscordClone.AccountsFixtures

    test "list_servers_for_user/1 returns all owned servers for a user" do
      user = user_fixture()
      server = server_fixture(%{user: user})
      assert Servers.list_servers_for_user(user.id) == [server]
    end

    test "list_member_servers_for_user/1 returns all servers user is a member of" do
      user1 = user_fixture()
      user2 = user_fixture()
      server1 = server_fixture(%{user: user1})
      server2 = server_fixture(%{user: user2})
      
      # user1 should be a member of server1 (as admin/owner) and server2 (as member)
      server_user_fixture(%{user: user1, server: server2, role: "member"})
      
      member_servers = Servers.list_member_servers_for_user(user1.id)
      server_ids = Enum.map(member_servers, & &1.id)
      
      assert server1.id in server_ids
      assert server2.id in server_ids
    end

    test "get_server!/1 returns the server with given id" do
      server = server_fixture()
      assert Servers.get_server!(server.id).id == server.id
    end

    test "get_user_server/2 returns server when user is the owner" do
      user = user_fixture()
      server = server_fixture(%{user: user})
      assert Servers.get_user_server(server.id, user.id).id == server.id
    end

    test "get_user_server/2 returns nil when user is not owner" do
      user1 = user_fixture()
      user2 = user_fixture()
      server = server_fixture(%{user: user1})
      assert Servers.get_user_server(server.id, user2.id) == nil
    end

    test "get_member_server/2 returns server when user is a member" do
      user1 = user_fixture()
      user2 = user_fixture()
      server = server_fixture(%{user: user1})
      server_user_fixture(%{user: user2, server: server})
      
      assert Servers.get_member_server(server.id, user2.id).id == server.id
    end

    test "create_server/1 with valid data creates a server and adds creator as admin" do
      user = user_fixture()
      valid_attrs = %{name: "Test Server", user_id: user.id}

      assert {:ok, %Server{} = server} = Servers.create_server(valid_attrs)
      assert server.name == "Test Server"
      assert server.user_id == user.id
      
      # Check that creator is automatically added as admin
      assert Servers.is_server_admin?(server.id, user.id)
    end

    test "create_server/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Servers.create_server(%{})
    end

    test "update_server/2 with valid data updates the server" do
      server = server_fixture()
      update_attrs = %{name: "Updated Server"}

      assert {:ok, %Server{} = updated_server} = Servers.update_server(server, update_attrs)
      assert updated_server.name == "Updated Server"
    end

    test "delete_server/1 deletes the server" do
      server = server_fixture()
      assert {:ok, %Server{}} = Servers.delete_server(server)
      assert_raise Ecto.NoResultsError, fn -> Servers.get_server!(server.id) end
    end

    test "change_server/1 returns a server changeset" do
      server = server_fixture()
      assert %Ecto.Changeset{} = Servers.change_server(server)
    end
  end

  describe "server membership" do
    import DiscordClone.ServersFixtures
    import DiscordClone.AccountsFixtures

    test "is_server_admin?/2 returns true for server admin" do
      user = user_fixture()
      server = server_fixture(%{user: user})
      
      assert Servers.is_server_admin?(server.id, user.id)
    end

    test "is_server_admin?/2 returns false for regular member" do
      user1 = user_fixture()
      user2 = user_fixture()
      server = server_fixture(%{user: user1})
      server_user_fixture(%{user: user2, server: server, role: "member"})
      
      refute Servers.is_server_admin?(server.id, user2.id)
    end

    test "is_server_member?/2 returns true for server members" do
      user1 = user_fixture()
      user2 = user_fixture()
      server = server_fixture(%{user: user1})
      server_user_fixture(%{user: user2, server: server})
      
      assert Servers.is_server_member?(server.id, user1.id)
      assert Servers.is_server_member?(server.id, user2.id)
    end

    test "add_user_to_server/3 adds user as member" do
      user1 = user_fixture()
      user2 = user_fixture()
      server = server_fixture(%{user: user1})
      
      assert {:ok, %ServerUser{} = server_user} = Servers.add_user_to_server(server.id, user2.id, "member")
      assert server_user.server_id == server.id
      assert server_user.user_id == user2.id
      assert server_user.role == "member"
    end

    test "remove_user_from_server/2 removes user from server" do
      user1 = user_fixture()
      user2 = user_fixture()
      server = server_fixture(%{user: user1})
      server_user_fixture(%{user: user2, server: server})
      
      assert {:ok, %ServerUser{}} = Servers.remove_user_from_server(server.id, user2.id)
      refute Servers.is_server_member?(server.id, user2.id)
    end

    test "list_server_members/1 returns all server members" do
      user1 = user_fixture()
      user2 = user_fixture()
      server = server_fixture(%{user: user1})
      server_user_fixture(%{user: user2, server: server})
      
      members = Servers.list_server_members(server.id)
      user_ids = Enum.map(members, & &1.user_id)
      
      assert user1.id in user_ids
      assert user2.id in user_ids
    end

    test "update_server_user_role/3 updates user role" do
      user1 = user_fixture()
      user2 = user_fixture()
      server = server_fixture(%{user: user1})
      server_user_fixture(%{user: user2, server: server, role: "member"})
      
      assert {:ok, %ServerUser{} = server_user} = Servers.update_server_user_role(server.id, user2.id, "admin")
      assert server_user.role == "admin"
      assert Servers.is_server_admin?(server.id, user2.id)
    end
  end
end