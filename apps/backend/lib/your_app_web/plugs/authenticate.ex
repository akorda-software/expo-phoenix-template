defmodule YourAppWeb.Plugs.Authenticate do
  @moduledoc """
  Plug that extracts and verifies the Bearer token from the Authorization header,
  then assigns the current user to the connection.
  """

  import Plug.Conn

  alias YourApp.Sessions
  alias YourApp.Auth

  @spec init(any()) :: any()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(conn, _opts) do
    case get_bearer_token(conn) do
      {:ok, token} ->
        case verify_token(token) do
          {:ok, claims} ->
            case fetch_user(claims) do
              {:ok, user} -> assign(conn, :current_user, user)
              _error -> halt_unauthorized(conn)
            end

          _error ->
            halt_unauthorized(conn)
        end

      _error ->
        halt_unauthorized(conn)
    end
  end

  defp get_bearer_token(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      [header | _] when is_binary(header) ->
        case String.split(header, " ", parts: 2) do
          ["Bearer", token] -> {:ok, token}
          _ -> {:error, :invalid_format}
        end

      _ ->
        {:error, :missing_header}
    end
  end

  defp verify_token(token) do
    case Phoenix.Token.verify(YourAppWeb.Endpoint, Auth.access_token_salt(), token,
           max_age: Auth.access_token_ttl_seconds()
         ) do
      {:ok, %{exp: exp} = claims} when is_integer(exp) ->
        if exp > System.os_time(:second), do: {:ok, claims}, else: {:error, :invalid_token}

      _ ->
        {:error, :invalid_token}
    end
  end

  defp fetch_user(%{sub: user_id, session_id: session_id}),
    do: Sessions.active_session_user(user_id, session_id)

  defp fetch_user(_claims), do: {:error, :invalid_claims}

  defp halt_unauthorized(conn) do
    conn
    |> put_status(401)
    |> Phoenix.Controller.json(%{error: "unauthorized"})
    |> halt()
  end
end
