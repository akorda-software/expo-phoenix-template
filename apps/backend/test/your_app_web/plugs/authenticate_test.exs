defmodule YourAppWeb.Plugs.AuthenticateTest do
  use YourAppWeb.ConnCase, async: true

  alias YourApp.{Accounts, Auth, Sessions}
  alias YourAppWeb.Plugs.Authenticate

  setup do
    {:ok, user} =
      Accounts.create_user(%{email: "auth-plug@example.test", display_name: "Auth User"})

    {:ok, issued} =
      Sessions.issue_session(user, %{
        installation_id: Ecto.UUID.generate(),
        platform: "ios",
        device_name: "Test"
      })

    %{user: user, issued: issued}
  end

  test "accepts an active session", %{issued: issued, user: user} do
    conn = authenticate(issued.session.access_token)
    refute conn.halted
    assert conn.assigns.current_user.id == user.id
  end

  test "rejects a signed token whose declared expiration has passed", %{
    issued: issued,
    user: user
  } do
    token =
      Phoenix.Token.sign(YourAppWeb.Endpoint, Auth.access_token_salt(), %{
        sub: user.id,
        session_id: issued.session_family.id,
        exp: System.os_time(:second) - 1
      })

    assert authenticate(token).status == 401
  end

  test "logout immediately invalidates access tokens", %{issued: issued} do
    Sessions.revoke_session(issued.session.refresh_token)
    assert authenticate(issued.session.access_token).status == 401
  end

  test "rejects invalid or missing session claims", %{user: user} do
    for claims <- [
          %{sub: user.id},
          %{sub: user.id, session_id: "bad-id", exp: System.os_time(:second) + 100}
        ] do
      token = Phoenix.Token.sign(YourAppWeb.Endpoint, Auth.access_token_salt(), claims)
      assert authenticate(token).status == 401
    end
  end

  defp authenticate(token) do
    build_conn() |> put_req_header("authorization", "Bearer #{token}") |> Authenticate.call([])
  end
end
