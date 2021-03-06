defmodule Mix.Tasks.Keys do
  use Mix.Task

  defp start_repo do
    [:postgrex, :ecto]
    |> Enum.each(&Application.ensure_all_started/1)
    Proca.Repo.start_link
  end

  defp generate(org_name) do
    start_repo()

    case Proca.Org.get_by_name(org_name) do
      nil -> IO.puts "no such org #{org_name}"
      o -> Proca.PublicKey.build_for(o) |> Proca.Repo.insert
    end
  end


  @shortdoc "Generate or import encryption keys for an org"
  def run(["generate", org_name]) do
    generate(org_name)
  end

  def run(["generate"]) do
    generate(Application.get_env(:proca, Proca)[:org_name])
  end

  def run(["import", "public", org_name, pub]) do
    start_repo()
    case Proca.Org.get_by_name(org_name) do
      nil -> IO.puts "no such org #{org_name}"
      o -> Proca.PublicKey.import_public_for(o, pub) |> Proca.Repo.insert
    end

  end
end
