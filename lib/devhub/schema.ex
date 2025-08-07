defmodule Devhub.Schema do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema

      import PolymorphicEmbed

      @foreign_key_type :string
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
