defmodule :vmq_json do
  @moduledoc """
  A mock for the :vmq_json module, not available without a running VerneMQ host.
  It is needed for handling HTTP requests to the VerneMQ endpoints.
  """
  def encode(body) do
    Jason.encode!(body)
  end
end
