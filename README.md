# AI Query Assistant

A Rails application that provides a chat interface for querying data using LangChain and Ollama.

## Prerequisites

- Ruby 3.x
- Rails 8.0.2
- Ollama (installed and running locally)
- [LangChain Ruby Gem](https://github.com/andreibondarev/langchainrb)

## Setup

1. Clone this repository
2. Install dependencies:

   ```
   bundle install
   ```

3. Start the Rails server:

   ```
   rails server
   ```

4. Open your browser to <http://localhost:3000>

## Features

- Chat interface with AI assistant
- Query loan data using natural language
- Seamless responses with Turbo Streams
- Modern UI with Tailwind CSS
- Different LLM model selection (Mistral, Llama3, etc.)

## Example Queries

- "Query loans where origination_amount is greater than 1500. Return 'loan_id' and 'origination_amount' as a JSON object."
- "Show me all loans with 'in_payment' status"
- "List all loans with an origination date before 2022"

## Architecture

The application uses:

- Rails 8.0.2 as the web framework
- Hotwire (Turbo) for seamless page updates
- LangChain Ruby for AI assistant functionality
- Ollama for running LLMs locally
- Tailwind CSS for styling

## Development

The main components of the application are:

- `QueryTool`: Handles data querying functionality
- `ChatsController`: Manages the chat interface and responses
- `chat_controller.js`: Stimulus controller for UI interactions
