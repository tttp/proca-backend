defmodule ProcaWeb.CampaignsController do
  use ProcaWeb, :live_view
  alias Proca.{Org,Staffer,Campaign,ActionPage}
  alias Proca.Users.User
  alias Proca.Repo
  import Ecto.Query
  import Ecto.Changeset


  def handle_event("campaign_new", _value, socket) do
    {
      :noreply,
      socket
      |> assign(:campaign, Campaign.changeset(%Campaign{}, %{}))
    }
  end

  def handle_event("action_page_new", %{"campaign_id" => campaign_id}, socket) do
    ch = ActionPage.changeset(%{})
    |> put_change(:org_id, socket.assigns[:staffer].org_id)

    IO.inspect(ch, label: "apch")
    {
      :noreply,
      socket
      |> assign(:action_page, ch)
      |> assign_selected_campaign(campaign_id)
      |> assign_partners
    }
  end

  def handle_event("action_page_edit", %{"id" => ap_id}, socket) do
    with ap <- ActionPage.find(ap_id) do
      {
        :noreply,
        socket
        |> assign(:action_page, ActionPage.changeset(ap, %{}))
        |> assign_selected_campaign(ap.campaign_id)
        |> assign_partners
      }
    end
  end


  def handle_event("action_page_save", %{"action_page" => attrs}, socket) do
    ch = socket.assigns[:action_page]

    org_id = socket.assigns[:staffer].org_id

    new_ch = ch.data
    |> ActionPage.changeset(Map.merge(%{"org_id" => org_id}, attrs))
    |> put_assoc(:campaign, socket.assigns[:selected_campaign])


    case Repo.insert_or_update(new_ch) do
      {:ok, _ap} ->
        {
          :noreply,
         socket
         |> assign(:action_page, nil)
         |> assign_campaigns
        }
      {:error, bad_ch} ->
        {
          :noreply,
          socket |> assign(:action_page, bad_ch)
        }
    end
  end

  def handle_event("action_page_remove", %{"id" => id}, socket) do
    org_id = socket.assigns[:staffer].org_id
    from(ap in ActionPage, where: ap.id == ^id and ap.org_id == ^org_id)
    |> Repo.delete_all
  end


  def handle_event("campaign_edit", %{"campaign_id" => cid}, socket) do
    {
      :noreply,
      socket
      |> assign(:campaign, Campaign.changeset(Repo.get(Campaign, cid), %{}))
    }
  end

  def handle_event("modal_discard", %{"modal" => modal}, socket) do
    s2 = case modal do
           "campaign" -> assign(socket, :campaign, nil)
           "action_page" -> assign(socket, :action_page, nil)
         end
    {:noreply,
     s2
    }
  end

  def handle_event("campaign_remove", %{"id" => cid}, socket) do
    c = Repo.get(Campaign, cid)
    {:ok, _c} = Repo.delete(c)

    {:noreply,
     socket
     |> assign(:campaign, nil)
     |> assign_campaigns
    }
  end

  def handle_event("campaign_save", %{"campaign" => campaign}, socket) do
    case socket.assigns[:campaign].data
    |> Campaign.changeset(campaign)
    |> put_change(:org_id, socket.assigns[:staffer].org.id)
    |> Repo.insert_or_update
      do
      {:ok, c} ->
        IO.inspect(c, label: "campaign_saved")
        {
          :noreply,
          socket
          |> assign(:campaign, nil)
          |> assign_campaigns
        }
      {:error, ch} ->
        IO.inspect(ch, label: "campaign_save")
        {
          :noreply,
          socket
          |> assign(:campaign, ch)
        }
    end
  end

  def render(assigns) do
    Phoenix.View.render(ProcaWeb.DashView, "campaigns.html", assigns)
  end

  def mount(_params, session, socket) do
    socket = mount_user(socket, session)

    {:ok,
     socket
     |> assign_campaigns
     |> assign(:campaign, nil)
     |> assign(:action_page, nil)
     |> assign(:partners, nil)
    }
  end

  def assign_campaigns(socket) do
    org_id = socket.assigns[:staffer].org_id

    cs = from(c in Campaign,
      where: c.org_id == ^org_id,
      preload: [:org, action_pages: :org],
      order_by: [desc: c.inserted_at])
    |> Repo.all

    partner_cs = from(c in Campaign,
      join: ap in ActionPage, on: c.id == ap.campaign_id,
      where: c.org_id != ^org_id and ap.org_id == ^org_id,
      preload: [:org, action_pages: :org],
      order_by: [desc: c.inserted_at],
      distinct: true)
    |> Repo.all
    |> Enum.map(fn c ->
      case c.org_id do
        ^org_id -> c
        _ -> %{c | action_pages: Enum.filter(c.action_pages, fn ap -> ap.org_id == org_id end)}
      end
    end)

    socket
    |> assign(:campaigns, cs ++ partner_cs)
  end

  def assign_partners(socket) do
    partners = Org.list |> Enum.map(fn o -> {o.name, o.id} end)
    assign(socket, :partners, partners)
  end

  def assign_selected_campaign(socket, campaign_id) when is_bitstring(campaign_id) do
    assign_selected_campaign(socket, String.to_integer(campaign_id))
  end

  def assign_selected_campaign(socket, campaign_id) when is_integer(campaign_id) do
    socket
    |> assign(:selected_campaign, Enum.find(
          socket.assigns[:campaigns],
        fn c -> c.id == campaign_id end))
  end

  def session_expired(socket) do
    {:noreply, socket}
  end
end
