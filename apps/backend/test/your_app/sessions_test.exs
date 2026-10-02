defmodule YourApp.SessionsTest do
  use YourApp.DataCase, async: true

  alias YourApp.Accounts
  alias YourApp.Sessions
  alias YourApp.Sessions.RefreshToken
  alias YourApp.Sessions.SessionFamily
  alias YourApp.Repo

  defp create_user! do
    {:ok, user} =
      Accounts.create_user(%{
        email: "session-user@example.com",
        display_name: "Session User"
      })

    user
  end

  defp device_attrs do
    %{
      installation_id: Ecto.UUID.generate(),
      platform: "ios",
      device_name: "iPhone 15"
    }
  end

  describe "issue_session/2" do
    test "creates a device-scoped session family and token bundle" do
      user = create_user!()

      assert {:ok, issued} = Sessions.issue_session(user, device_attrs())

      assert issued.session.user.id == user.id
      assert issued.session.refresh_token != ""
      assert issued.session.access_token != ""
      assert Repo.aggregate(SessionFamily, :count, :id) == 1
      assert Repo.aggregate(RefreshToken, :count, :id) == 1
    end
  end

  describe "refresh_session/1" do
    test "a revoked replacement token cannot refresh" do
      user = create_user!()
      {:ok, issued} = Sessions.issue_session(user, device_attrs())
      {:ok, refreshed} = Sessions.refresh_session(issued.session.refresh_token)

      assert {:error, :refresh_token_reused} =
               Sessions.refresh_session(issued.session.refresh_token)

      assert {:error, :session_revoked} =
               Sessions.refresh_session(refreshed.session.refresh_token)
    end

    test "a token expiring now cannot refresh" do
      user = create_user!()
      {:ok, issued} = Sessions.issue_session(user, device_attrs())

      Repo.update_all(RefreshToken,
        set: [expires_at: DateTime.utc_now() |> DateTime.truncate(:second)]
      )

      assert {:error, :session_revoked} = Sessions.refresh_session(issued.session.refresh_token)
    end

    test "rotates the refresh token and invalidates the prior token" do
      user = create_user!()
      {:ok, issued} = Sessions.issue_session(user, device_attrs())

      assert {:ok, refreshed} = Sessions.refresh_session(issued.session.refresh_token)
      assert refreshed.session.refresh_token != issued.session.refresh_token

      assert {:error, :refresh_token_reused} =
               Sessions.refresh_session(issued.session.refresh_token)
    end

    test "revokes the entire family after refresh token reuse" do
      user = create_user!()
      {:ok, issued} = Sessions.issue_session(user, device_attrs())
      {:ok, _refreshed} = Sessions.refresh_session(issued.session.refresh_token)

      assert {:error, :refresh_token_reused} =
               Sessions.refresh_session(issued.session.refresh_token)

      family = Repo.one!(SessionFamily)
      assert family.revoked_at != nil
    end
  end
end
