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

      {:ok, index_live, _html} = live(conn, ~p"/servers")

      # Open create form - click the button in the empty state
      assert index_live |> element("button[phx-click='show_create_form']") |> render_click()
      assert has_element?(index_live, "h2", "Create New Server")

      # Submit form
      assert index_live
             |> form("[phx-submit='create_server']", server: %{name: "My New Server"})
             |> render_submit()

      # Check that the server was created and appears in the list
      html = render(index_live)
      assert html =~ "My New Server"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/servers")

      assert {:redirect, %{to: "/users/log_in"}} = redirect
    end
  end
end