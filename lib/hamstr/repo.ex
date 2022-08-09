defmodule Hamstr.Repo do
  use Ecto.Repo,
    otp_app: :hamstr,
    adapter: Ecto.Adapters.Postgres
end
