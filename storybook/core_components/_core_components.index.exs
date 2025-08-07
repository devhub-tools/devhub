defmodule Storybook.CoreComponents do
  @moduledoc false
  use PhoenixStorybook.Index

  def folder_open?, do: true

  def entry("back"), do: [icon: {:fa, "circle-left", :thin}]
  def entry("badge"), do: [icon: {:local, "hero-check-badge-mini"}]
  def entry("button"), do: [icon: {:fa, "rectangle-ad", :thin}]
  def entry("error"), do: [icon: {:local, "hero-exclamation-circle"}]
  def entry("flash"), do: [icon: {:fa, "bolt", :thin}]
  def entry("header"), do: [icon: {:fa, "heading", :thin}]
  def entry("icon"), do: [icon: {:fa, "icons", :thin}]
  def entry("input"), do: [icon: {:fa, "input-text", :thin}]
  def entry("link_button"), do: [icon: {:fa, "link", :thin}]
  def entry("list"), do: [icon: {:fa, "list", :thin}]
  def entry("logo"), do: [icon: {:fa, "bolt", :thin}]
  def entry("shield_badge"), do: [icon: {:local, "hero-check-badge-mini"}]
  def entry("spinner"), do: [icon: {:fa, "circle-exclamation", :thin}]
  def entry("table"), do: [icon: {:fa, "table", :thin}]
  def entry("toggle_button"), do: [icon: {:fa, "toggle-on", :thin}]
end
