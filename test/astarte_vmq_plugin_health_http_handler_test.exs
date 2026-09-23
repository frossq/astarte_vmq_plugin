defmodule Astarte.VMQ.Plugin.HealthHttp.HandlerTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Astarte.VMQ.Plugin.HealthHttp.Handler
  alias Mississippi.Producer.Healthcheck

  # allow cowboy to spawn secondary processes to retrieve Mississippi state
  setup :set_mimic_global

  setup do
    # define the custom routes and start a cowboy listener exposing them
    dispatch = :cowboy_router.compile([{:_, Handler.routes()}])

    {:ok, _pid} =
      :cowboy.start_clear(
        :cowboy_server,
        [{:port, 0}],
        %{env: %{dispatch: dispatch}}
      )

    port = :ranch.get_port(:cowboy_server)

    on_exit(fn ->
      :cowboy.stop_listener(:cowboy_server)
    end)

    %{url: "http://127.0.0.1:#{port}/healthz"}
  end

  describe "/healthz endpoint" do
    test "returns 200 if Mississippi healthcheck reports no errors", %{url: url} do
      expect(Healthcheck, :check_all, fn -> :ok end)

      assert %Req.Response{status: 200, body: %{"status" => "OK"}} = Req.get!(url, retry: false)
    end

    test "returns 503 if Mississippi healthcheck reports a list of errors", %{url: url} do
      expect(Healthcheck, :check_all, fn -> {:error, [:some, :issues, :encountered]} end)

      assert %Req.Response{
               status: 503,
               body: %{"status" => "DOWN", "reasons" => ["some", "issues", "encountered"]}
             } = Req.get!(url, retry: false)
    end

    test "returns 500 if unexpected data arrives from Mississippi", %{url: url} do
      expect(Healthcheck, :check_all, fn -> :unexpected end)

      assert %Req.Response{status: 500} = Req.get!(url, retry: false)
    end
  end
end
