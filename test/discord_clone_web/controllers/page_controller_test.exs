defmodule DiscordCloneWeb.PageControllerTest do
  use DiscordCloneWeb.ConnCase

  import DiscordClone.AccountsFixtures

  test "GET / redirects to login when user is not authenticated", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/users/log_in"
  end

  test "GET / redirects to servers when user is authenticated", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/servers"
  end
end
