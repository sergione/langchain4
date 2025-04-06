require_relative "../models/concerns/id_helpers"

class ChatsController < ApplicationController
  def index
    @messages = []
  end

  def create
    @query = params[:message]
    @model = "mistral:latest"
    @message_id = IdHelpers.generate_unique_id

    respond_to do |format|
      format.turbo_stream do
        # First, render the user's message and loading indicator
        render turbo_stream: [
          turbo_stream.append("messages", partial: "messages/user_message", locals: { message: @query }),
          turbo_stream.append("messages", partial: "messages/loading_message", locals: { message_id: @message_id }),
          turbo_stream.replace("chat_message",
            "<input id='chat_message' name='message' class='block w-full rounded-md border-0 px-4 py-2.5 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600' placeholder='Type your query here...' data-action='keydown.enter->chat#submitOnEnter' data-chat-target='messageInput' autocomplete='off'>")
        ]

        # Process with LangChain in a background thread
        Thread.new do
          begin
            # Process query
            result = process_query(@query, @model)

            # Render response directly through Turbo
            response = ApplicationController.renderer.render(
              partial: "messages/assistant_message",
              locals: { result: result, message_id: @message_id }
            )

            # Use Turbo Streams to replace the loading message
            Turbo::StreamsChannel.broadcast_replace_later_to(
              "chat_updates",
              target: "message_#{@message_id}",
              html: response
            )
          rescue => e
            # Handle errors
            error_response = ApplicationController.renderer.render(
              partial: "messages/assistant_message",
              locals: { result: "Error: #{e.message}", message_id: @message_id }
            )

            Turbo::StreamsChannel.broadcast_replace_later_to(
              "chat_updates",
              target: "message_#{@message_id}",
              html: error_response
            )
          ensure
            # Make sure thread is terminated
            ActiveRecord::Base.connection_pool.release_connection if defined?(ActiveRecord::Base)
          end
        end
      end
    end
  end

  private

  def process_query(message, model_name)
    llm = Langchain::LLM::Ollama.new(default_options: { chat_model: model_name })

    assistant = Langchain::Assistant.new(
      llm: llm,
      instructions: "You are a database query assistant. Help users query loan data through the provided tool. Always format your final response as valid JSON. If the result is an array, keep it as an array of objects.",
      tools: [ QueryTool.new ]
    )

    assistant.add_message_and_run(content: message, auto_tool_execution: true)

    # Debug logging
    Rails.logger.info "Messages from assistant:"
    assistant.messages.each_with_index do |msg, idx|
      Rails.logger.info "Message #{idx}: #{msg.class}"
      Rails.logger.info "  Content: #{msg.content}"
      if msg.tool_calls
        Rails.logger.info "  Tool Calls: #{msg.tool_calls.class} (count: #{msg.tool_calls.size})"
        msg.tool_calls.each_with_index do |tc, tc_idx|
          Rails.logger.info "    Tool Call #{tc_idx}: #{tc.class}"
          Rails.logger.info "    Tool Call inspect: #{tc.inspect}"
          Rails.logger.info "    Methods: #{tc.methods - Object.methods}" if tc.respond_to?(:methods)
        end
      end
    end

    # Get the actual results from the tool execution
    tool_results = nil
    assistant.messages.each do |msg|
      if msg.tool_calls && !msg.tool_calls.empty?
        msg.tool_calls.each do |tool_call|
          # Check if it's a Hash (direct response) or an object with name/response methods
          if tool_call.is_a?(Hash) && tool_call["name"] == "query" && tool_call["response"]
            Rails.logger.info "Found hash tool call with query response"
            tool_results = tool_call["response"]
            break
          elsif tool_call.respond_to?(:name) && tool_call.name == "query" && tool_call.respond_to?(:response)
            Rails.logger.info "Found object tool call with query response"
            tool_results = tool_call.response
            break
          elsif tool_call.is_a?(Hash) && tool_call.key?("function")
            # Handle structured format
            Rails.logger.info "Found tool call with function key"
            function = tool_call["function"]
            if function["name"] == "query" && tool_call["response"]
              tool_results = tool_call["response"]
              break
            end
          elsif tool_call.respond_to?(:function) && tool_call.function.respond_to?(:name)
            Rails.logger.info "Found tool call with function method"
            if tool_call.function.name == "query" && tool_call.respond_to?(:response)
              tool_results = tool_call.response
              break
            end
          end
        end
      end
      break if tool_results
    end

    if tool_results
      Rails.logger.info "Tool results: #{tool_results.class} - #{tool_results.inspect}"
      if tool_results.is_a?(Array)
        JSON.pretty_generate(tool_results)
      else
        tool_results.inspect
      end
    else
      Rails.logger.info "No tool results found, returning last message content"
      assistant.messages.last.content
    end
  rescue => e
    Rails.logger.error "Error in process_query: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    "Error processing query: #{e.message} (#{e.class})"
  end
end
