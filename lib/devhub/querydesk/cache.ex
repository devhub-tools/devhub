defmodule Devhub.QueryDesk.Cache do
  @moduledoc false
  use Nebulex.Cache,
    otp_app: :devhub,
    adapter: Nebulex.Adapters.Local
end
