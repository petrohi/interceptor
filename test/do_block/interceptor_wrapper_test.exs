defmodule InterceptorWrapperTest do
  use ExUnit.Case

  @process_name :wrapper_test_process

  describe "module with a single function" do
    test "it intercepts the function passing it as a lambda" do
      {:ok, _pid} = spawn_agent()

      result = InterceptedByWrapper1.to_intercept()

      callback_calls = get_agent_messages()

      [{_intercepted_timestamp, callback_result, intercepted_mfa}] = callback_calls

      assert length(callback_calls) == 1
      assert result == callback_result
      assert intercepted_mfa == {InterceptedByWrapper1, :to_intercept, []}
    end
  end

  describe "module with two functions and other statement" do
    test "it intercepts the function passing it as a lambda" do
      {:ok, _pid} = spawn_agent()

      result = InterceptedByWrapper2.to_intercept()

      callback_calls = get_agent_messages()

      [{intercepted_timestamp, callback_result, intercepted_mfa}] = callback_calls

      assert length(callback_calls) == 1
      assert result == callback_result
      assert intercepted_timestamp > result
      assert intercepted_mfa == {InterceptedByWrapper2, :to_intercept, []}
    end

    test "it also intercepts the other function" do
      {:ok, _pid} = spawn_agent()

      result = InterceptedByWrapper2.other_to_intercept()

      callback_calls = get_agent_messages()

      [{_intercepted_timestamp, callback_result, intercepted_mfa}] = callback_calls

      assert length(callback_calls) == 1
      assert result == callback_result
      assert result == "HELLO"
      assert intercepted_mfa == {InterceptedByWrapper2, :other_to_intercept, []}
    end
  end

  describe "module with two functions and a private one" do
    test "it intercepts the function" do
      {:ok, _pid} = spawn_agent()

      result = InterceptedByWrapper3.other_to_intercept(4)

      callback_calls = get_agent_messages()

      [{_intercepted_timestamp, result_callback, intercepted_mfa}] = callback_calls

      assert length(callback_calls) == 1
      assert result == result_callback
      assert result == 10
      assert intercepted_mfa == {InterceptedByWrapper3, :other_to_intercept, [4]}
    end

    test "it doesn't intercept the function that isn't configured" do
      {:ok, _pid} = spawn_agent()

      now = Interceptor.Utils.timestamp()
      Process.sleep(50)
      result = InterceptedByWrapper3.not_to_intercept()

      callback_calls = get_agent_messages()

      assert result > now
      assert length(callback_calls) == 0
    end
  end

  describe "other module with a single function" do
    test "it intercepts the function passing it as a lambda and changes the return value" do
      {:ok, _pid} = spawn_agent()

      result = InterceptedByWrapper4.to_intercept()

      callback_calls = get_agent_messages()

      [{_intercepted_timestamp, callback_result, intercepted_mfa}] = callback_calls

      assert length(callback_calls) == 1
      assert result != callback_result
      assert result == "Hello"
      assert intercepted_mfa == {InterceptedByWrapper4, :to_intercept, []}
    end
  end

  defp spawn_agent() do
    @process_name
    |> Process.whereis()
    |> kill_agent()

    {:ok, pid} = Agent.start_link(fn -> [] end)
    true = Process.register(pid, @process_name)

    {:ok, pid}
  end

  defp kill_agent(nil), do: false
  defp kill_agent(pid) do
    case Process.alive?(pid) do
      true -> Process.exit(pid, :kill)
      _ -> false
    end
  end

  defp get_agent_messages(), do: Agent.get(@process_name, &(&1))
end
