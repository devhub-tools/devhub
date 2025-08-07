defmodule Devhub.Types.EncryptedEmbed do
  @moduledoc false
  use Cloak.Ecto.Binary, vault: Devhub.Vault, embed: true
end
