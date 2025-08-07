defmodule DevhubWeb.Proxy.Postgres.ClientState do
  @moduledoc false
  defstruct [:conn, :database, :database_conn, :organization_user, :connect_params, :scram_state, :user]
end

defmodule DevhubWeb.Proxy.Postgres.DatabaseState do
  @moduledoc false
  defstruct [:conn, :database, :client_conn]
end
