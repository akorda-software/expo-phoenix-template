defmodule YourApp.SessionsConcurrencyTest do
  use ExUnit.Case, async: false
  import Ecto.Query
  alias Ecto.Adapters.SQL.Sandbox
  alias YourApp.{Accounts, Repo, Sessions}
  alias YourApp.Sessions.{Device, RefreshToken, SessionFamily}

  test "concurrent refreshes cannot create multiple active successors" do
    {user, issued} =
      Sandbox.unboxed_run(Repo, fn ->
        {:ok, user} =
          Accounts.create_user(%{
            email: "race-#{Ecto.UUID.generate()}@example.test",
            display_name: "Race Test"
          })

        {:ok, issued} =
          Sessions.issue_session(user, %{
            installation_id: Ecto.UUID.generate(),
            platform: "ios",
            device_name: "Race"
          })

        {user, issued}
      end)

    on_exit(fn ->
      Sandbox.unboxed_run(Repo, fn ->
        Repo.delete_all(
          from(t in RefreshToken, where: t.session_family_id == ^issued.session_family.id)
        )

        Repo.delete_all(from(f in SessionFamily, where: f.user_id == ^user.id))
        Repo.delete_all(from(d in Device, where: d.user_id == ^user.id))
        Repo.delete!(user)
      end)
    end)

    results =
      1..8
      |> Task.async_stream(
        fn _ ->
          Sandbox.unboxed_run(Repo, fn ->
            Sessions.refresh_session(issued.session.refresh_token)
          end)
        end,
        max_concurrency: 8
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.count(results, &match?({:ok, _}, &1)) == 1

    assert Enum.all?(results, fn
             {:ok, _} -> true
             {:error, reason} -> reason in [:refresh_token_reused, :session_revoked]
           end)

    Sandbox.unboxed_run(Repo, fn ->
      assert Repo.get!(SessionFamily, issued.session_family.id).revoked_at != nil

      assert Repo.aggregate(
               from(t in RefreshToken,
                 where: t.session_family_id == ^issued.session_family.id and t.status == "active"
               ),
               :count
             ) == 0
    end)
  end
end
