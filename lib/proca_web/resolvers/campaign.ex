defmodule ProcaWeb.Resolvers.Campaign do
  import Ecto.Query


  def list(_, %{id: id}, _) do
    cl = list_query()
    |> where([x], x.id == ^id)
    |> Proca.Repo.all

    {:ok, cl}
  end

  def list(_, %{name: name}, _) do
    cl = list_query()
    |> where([x], x.name == ^name)
    |> Proca.Repo.all

    {:ok, cl}
  end

  def list(_, %{title: title}, _) do
    cl = list_query()
    |> where([x], like(x.title, ^title))
    |> Proca.Repo.all

    {:ok, cl}
  end

  def list(_, _, _) do
    cl = Proca.Repo.all list_query()
    {:ok, cl}
  end

  defp list_query() do
    from(x in Proca.Campaign, preload: [:org])
  end

  def stats(campaign, _, _) do
    sig_ct = Proca.Repo.one(from s in Proca.Signature,
      where: s.campaign_id == ^campaign.id,
      select: count(s.fingerprint, :distinct))

    {:ok,
     %{
       signature_count: sig_ct
     }
    }
  end
end
