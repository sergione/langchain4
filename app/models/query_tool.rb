require "langchain"
require "json"

class QueryTool
  extend Langchain::ToolDefinition

  define_function :query, description: "Query the api for information about loans" do
    property :select, type: "array", description: "The attributes to select from the data. If not provided, all attributes will be returned. For loans, the attributes are: id, loan_id, origination_amount, origination_date, status. Status can be in_payment, charged_off, matured."
    property :from, type: "string", enum: [ "loans", "movies" ], description: "The model to query from. Must be one of: loans, movies."
    property :where, type: "array", description: "The conditions to filter the results. Make sure it's valid JSON. Examples: [{ column: 'status', value: 'matured', condition: \"=\" }], [{ column: 'origination_amount', value: '1500', condition: \">=\" }]" do
      item type: "object", description: "A condition to filter the results." do
        property :column, type: "string", enum: [ "id", "loan_id", "origination_amount", "origination_date", "status" ], description: "The column to filter on."
        property :value, type: "string", description: "The value to filter on."
        property :condition, type: "string", enum: [ "=", ">", "<", ">=", "<=", "!=" ], description: "The condition to filter on."
      end
    end
  end

  def query(select: nil, from: nil, where: nil)
    Rails.logger.info "Query executed: #{select} from #{from} where #{where}"

    results = []

    results = get_data_from(from)

    results = filter_results(results, where) if where && !where.empty?

    results = select_attributes(results, select) if select && !select.empty?

    results
  end

  private

  def select_attributes(results, select)
    Rails.logger.info "Selecting attributes: #{select}"

    select = JSON.parse(select) if select.is_a?(String)

    select_attrs = select.map(&:to_sym)
    results.map do |item|
      selected_item = {}
      select_attrs.each do |attr|
        selected_item[attr] = item[attr] if item.key?(attr)
      end
      selected_item
    end
  end

  def filter_results(results, where)
    return results if where.nil? || where.empty?
    Rails.logger.info "Filtering results with conditions: #{where}. Is 'where' an array? #{where.is_a?(Array)}"

    where = JSON.parse(where) if where.is_a?(String)

    where.each do |condition|
      column = condition["column"].to_sym
      value = condition["value"]
      operator = condition["condition"]

      results = results.select do |item|
        item_value = item[column]
        case operator
        when "=", "!="
          # String comparison for equality operators
          item_str = item_value.to_s
          value_str = value.to_s
          operator == "=" ? item_str == value_str : item_str != value_str
        when ">", "<", ">=", "<="
          # Numeric comparison for relational operators
          item_num = item_value.to_f
          value_num = value.to_f
          case operator
          when ">" then item_num > value_num
          when "<" then item_num < value_num
          when ">=" then item_num >= value_num
          when "<=" then item_num <= value_num
          end
        else
          item_value.to_s == value.to_s
        end
      end
    end
    results
  end

  def get_data_from(from)
    if from == "loans"
      loans
    elsif from == "movies"
      movies
    end
  end

  def loans
    [
      { id: 1, loan_id: "L12346", origination_amount: 10000, origination_date: "2022-01-15", status: "in_payment" },
      { id: 2, loan_id: "L32445", origination_amount: 25000, origination_date: "2021-06-30", status: "charged_off" },
      { id: 3, loan_id: "L98765", origination_amount: 15000, origination_date: "2020-03-22", status: "matured" },
      { id: 4, loan_id: "L45678", origination_amount: 30000, origination_date: "2022-09-10", status: "in_payment" },
      { id: 5, loan_id: "L23456", origination_amount: 50000, origination_date: "2021-11-05", status: "charged_off" }
    ]
  end

  def movies
    []  # Add movie data if needed
  end
end
