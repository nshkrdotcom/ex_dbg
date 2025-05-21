defmodule ElixirScope.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_scope,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:telemetry, "~> 1.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:phoenix, "~> 1.6", optional: true},
      {:phoenix_live_view, "~> 0.17", optional: true}
    ]
  end

  defp description do
    """
    ElixirScope: Advanced Introspection and Debugging for Phoenix Applications

    A state-of-the-art Elixir introspection and debugging system with special focus
    on Phoenix applications. It enables comprehensive tracking of processes, message
    passing, and state changes with AI-assisted analysis capabilities.
    """
  end

  defp package do
    [
      maintainers: ["Your Name"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/yourusername/elixir_scope"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "doc/CURSOR.md"]
    ]
  end
end 