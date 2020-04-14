defmodule PokerXWeb.EndToEndTest do
  use PokerXWeb.ConnCase
  import Phoenix.LiveViewTest
  @endpoint PokerXWeb.Endpoint

  test "Login enforcement/redirect", %{conn: conn} do
    conn = get(conn, "/tables")
    assert response(conn, 302)
    assert redirected_to(conn) =~ "/login"
    assert {:error, %{redirect: %{to: "/login"}}} = live(conn)

    conn = get(conn, "/tables/Test")
    assert response(conn, 302)
    assert redirected_to(conn) =~ "/login"

    assert {:error, %{redirect: %{to: "/login"}}} = live(conn)
  end

  test "To the Tables! Workflow", %{conn: conn} do
    # Open Login Page
    {conn, conn_resp} =
      conn
      |> get(Routes.session_path(conn, :login))
      |> piped_recycle

    response = html_response(conn_resp, 200)
    assert response =~ "Username"
    assert response =~ "Password"

    # Do the login call
    {conn, conn_resp} =
      conn
      |> post(Routes.session_path(conn, :login), %{"username" => "my-test", "password" => "pass"})
      |> piped_recycle

    assert redirected_to(conn_resp) =~ "/tables"

    # Go to the Tables
    {:ok, view, html} = live(conn, "/tables")
    assert PokerXWeb.TableLive.Index == view.module

    {:ok, view, html} = live(conn, "/tables/Champions")
    assert PokerXWeb.TableLive.Index == view.module
  end

  test "4 Player Gambling" do
    table_name = "Champions"
    table_pid = PokerX.Table.whereis(table_name)
    players = ["player-1", "player-2", "player-3", "player-4"]
    players_conn = create_player_sessions(players)

    # Everyone, to the table!
    player_views =
      Enum.map(players_conn, fn conn ->
        {:ok, view, html} = live(conn, "/tables/#{table_name}")
        assert html =~ "id=\"seat-1\""
        view
      end)

    # p1 to s1
    render_click([Enum.at(player_views, 0), "#seat-1"], "sit", %{})
    #    assert render(Enum.at(player_views, 0)) =~ "bg-green-50\" id=\"seat-1\""

    # ERROR: p2 to s1
    render_click([Enum.at(player_views, 1), "#seat-1"], "sit", %{})
    assert render(Enum.at(player_views, 1)) =~ "seat_taken"

    # Seat everyone.
    Enum.map(1..3, fn i ->
      render_click([Enum.at(player_views, i), "#seat-#{i + 1}"], "sit", %{})
      #      assert render(Enum.at(player_views, i)) =~ "bg-green-50\" id=\"seat-#{i + 1}\""
    end)

    # Buy in everyone with 400, but no money :shrug:. => insufficient_funds
    Enum.map(0..3, fn i ->
      render_click([Enum.at(player_views, i), "#seat-#{i + 1}"], "table-buy_in", %{
        "amount" => "400"
      })

      html = render(Enum.at(player_views, i))
      assert html =~ "Balance: <span class=\"text-red-500\">0</span>"
      assert html =~ "insufficient_funds"
    end)

    # Add money to bank!
    Enum.map(players, &PokerX.Bank.deposit(&1, 500))

    Enum.map(0..3, fn i ->
      render_click([Enum.at(player_views, i), "#seat-#{i + 1}"], "table-buy_in", %{
        "amount" => "400"
      })

      html = render(Enum.at(player_views, i))
      assert html =~ "Balance: <span class=\"text-green-500\">400</span>"
    end)

    # Start the Game!
    table_state = PokerX.Table.get_state(table_pid)
    hand_pid = PokerX.Hand.whereis(table_state.hand)
    assert %{phase: :initial} = PokerX.Hand.get_state(hand_pid) |> IO.inspect()
    render_click([List.first(player_views), "#manage-table"], "deal", %{})

    assert %{phase: :blinds} = PokerX.Hand.get_state(hand_pid) |> IO.inspect()

    index_player_views =
      Enum.with_index(player_views)
      |> Enum.map(fn {view, index} -> {index, view} end)
      |> Map.new()

    render_click([index_player_views[0], "#hand"], "bet", %{"amount" => "5"})
    render_click([index_player_views[1], "#hand"], "bet", %{"amount" => "10"})

    assert %{phase: :pre_flop} = PokerX.Hand.get_state(hand_pid) |> IO.inspect()
    # Cards should now be available

    active_p = active_player(hand_pid)
    p_view = Enum.at(player_views, active_p.position)
    html = render(p_view)
    render_click([p_view, "#hand"], "check", %{})
  end

  defp active_player(hand_pid) do
    hand_state = PokerX.Hand.get_state(hand_pid) |> IO.inspect()
    player = Enum.find(hand_state.players, &(&1.active == true))
  end

  defp create_player_sessions(players) do
    Enum.map(players, fn player ->
      {conn, conn_resp} =
        conn
        |> post(Routes.session_path(conn, :login), %{"username" => player, "password" => "pass"})
        |> piped_recycle

      conn
    end)
  end

  defp piped_recycle(conn) do
    {recycle(conn), conn}
  end
end
