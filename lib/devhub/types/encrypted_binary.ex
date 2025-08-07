defmodule Devhub.Types.EncryptedBinary do
  @moduledoc false
  use Cloak.Ecto.Binary, vault: Devhub.Vault
end
