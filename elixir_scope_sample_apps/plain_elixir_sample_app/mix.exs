defmodule ElixirSampleApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_sample_app,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ElixirSampleApp.Application, []}
    ]
  end

  defp deps do
    [
      # Path dependency to ElixirScope
      {:elixir_scope, path: "../cursor"}
    ]
  end
end 