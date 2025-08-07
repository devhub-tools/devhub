defmodule Devhub.Portal.Charts.Behaviour do
  @moduledoc false
  @callback title() :: String.t()
  @callback tooltip() :: String.t()
  @callback data(organization_id :: integer(), opts :: Keyword.t()) :: list()
  @callback line_chart_config(data :: list()) :: %{
              data: [number()],
              labels: [String.t()],
              links: [String.t()]
            }
  @callback bar_chart_config(data :: list()) ::
              %{
                data: [number()],
                labels: [String.t()],
                links: [String.t()]
              }
  @callback enable_line_chart() :: boolean()
  @callback enable_bar_chart() :: boolean()
  @callback line_chart_data(organization_id :: integer(), opts :: Keyword.t()) :: list()
  @callback bar_chart_data(organization_id :: integer(), opts :: Keyword.t()) :: list()
end
