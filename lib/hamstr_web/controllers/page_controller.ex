defmodule HamstrWeb.PageController do
  use HamstrWeb, :controller

  def index(conn, _params) do
    path = Routes.live_path(conn, HamstrWeb.IndexLive)

    conn
    |> redirect(to: path)
    |> halt()
  end
end
