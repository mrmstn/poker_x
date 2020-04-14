defmodule PokerXWeb.Router do
  use PokerXWeb, :router
  import Phoenix.LiveView.Router
  alias PokerXWeb.Plugs.Authenticate

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {PokerXWeb.LayoutView, :root}
  end

  pipeline :authorized do
    plug Authenticate
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :bare do
    plug :put_root_layout, {PokerXWeb.LayoutView, :bare}
  end

  scope "/", PokerXWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/login", SessionController, :login
    post "/login", SessionController, :load_session
  end

  scope "/", PokerXWeb do
    pipe_through :browser
    pipe_through :authorized

    live "/tables", TableLive.Index
    live "/tables/:id", TableLive.Show
  end

  # Other scopes may use custom stacks.
  # scope "/api", PokerXWeb do
  #   pipe_through :api
  # end
end
