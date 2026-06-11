class ApiCallHelper
  def initialize(base_url:)
    @connection = Faraday.new(url: base_url) do |conn|
      conn.response :json
    end
  end

  # Makes a get call and does error handling
  #
  # @param path [string] The path name
  # @param query [string] The query to attach (if one is provided)
  # @return [Hash] The parsed response body or nil on error
  def make_get_call(path:, query: nil)
    path += "?#{query}" if query.present?

    response = @connection.get(path)

    if response.status >= 300
      puts "#{response.status} status response."
      return nil
    end

    response.body
  rescue Faraday::Error => e
    puts "Faraday ran into an error: #{e.message}"
    nil
  end
end
