defmodule DiscordCloneWeb.ServersLiveTest do
  use DiscordCloneWeb.ConnCase

  import Phoenix.LiveViewTest
  import DiscordClone.AccountsFixtures
  import DiscordClone.ServersFixtures

  describe "Index" do
    test "renders servers page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _index_live, html} = live(conn, ~p"/servers")

      assert html =~ "My Servers"
      assert html =~ "Create Server"
    end

    test "shows user's servers", %{conn: conn} do
      user = user_fixture()
      _server = server_fixture(%{user: user, name: "Test Server"})
      conn = log_in_user(conn, user)

      {:ok, _index_live, html} = live(conn, ~p"/servers")

      assert html =~ "Test Server"
    end

    test "creates new server", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _index_live, _html} = live(conn, ~p"/servers")

      # Navigate to create form
      {:ok, form_live, _html} = live(conn, ~p"/servers/new") 
      assert has_element?(form_live, "h2", "Create New Server")

      # Submit form
      form_live
      |> form("[phx-submit='save']", server: %{name: "My New Server"})
      |> render_submit()
      
      # Verify the server was created by checking the database
      servers = DiscordClone.Servers.list_member_servers_for_user(user.id)
      assert Enum.any?(servers, fn s -> s.name == "My New Server" end)
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/servers")

      assert {:redirect, %{to: "/users/log_in"}} = redirect
    end
  end
end