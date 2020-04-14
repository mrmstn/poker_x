defmodule PokerX.Subscribable do
  defmacro __using__(_) do
    quote do
      @topic inspect(__MODULE__)
      alias Phoenix.PubSub

      def subscribe do
        PubSub.subscribe(PokerX.PubSub, @topic)
      end

      def subscribe(sub_topic) do
        PubSub.subscribe(PokerX.PubSub, @topic <> ":#{sub_topic}")
      end

      defp notify_subscribers(state, event, sub_topic \\ nil) do
        PubSub.broadcast(PokerX.PubSub, @topic, {__MODULE__, event, state})

        unless is_nil(sub_topic) do
          PubSub.broadcast(PokerX.PubSub, @topic <> ":#{sub_topic}", {__MODULE__, event, state})
        end

        state
      end
    end
  end
end
