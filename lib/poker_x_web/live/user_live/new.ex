defmodule PokerXWeb.UserLive.New do
  use Phoenix.LiveView

  alias PokerXWeb.UserLive
  alias PokerXWeb.Router.Helpers, as: Routes
  alias PokerX.Accounts
  alias PokerX.Accounts.User

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user(%User{})
    {:ok, assign(socket, changeset: changeset)}
  end

  def render(assigns), do: Phoenix.View.render(PokerXWeb.UserView, "new.html", assigns)

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      %User{}
      |> PokerX.Accounts.change_user(user_params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "user created")
         |> redirect(to: Routes.live_path(socket, UserLive.Show, user))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("blur", _, socket) do
    {:noreply, socket}
  end
end
