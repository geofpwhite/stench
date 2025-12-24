defmodule Stench.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_calc,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
      # default_task: "Stench.CLI.main"
    ]
  end

  defp escript do
    [main_module: Stench.CLI, name: "calc"]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
