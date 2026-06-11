# frozen_string_literal: true

require "faraday"

class ForecastService
  BASE_COORDINATES_ENDPOINT = "https://geocode.maps.co/"
  COORDINATES_PATH = "search"
  BASE_WEATHER_ENDPOINT = "https://api.open-meteo.com"
  WEATHER_PATH = "v1/forecast"

  DAILY_REQUESTED_DATA = [
    "temperature_2m_max",
    "temperature_2m_min"
]

  CURRENT_REQUESTED_DATA = [
    "temperature_2m",
    "precipitation"
]

  # Takes an address an interacts with 3rd party APIs in order to get forecast information
  #
  # @params address [string] Address to identify
  # @return forecast [Hash] Forecast for provided address, or nil if failed to gather
  def self.get_forecast(address:)
    return nil if address.blank?

    uri_escaped_address = URI::Parser.new.escape(address)

    location = get_location(uri_escaped_address: uri_escaped_address)

    return nil if location.blank?

    @forecast = get_forecast_info(location: location)
  rescue => e
    puts "Unexpected error while getting forecast: #{e.message}"
    nil
  end

  private

  def self.get_location(uri_escaped_address:)
    api_key = ENV["GEOCODE_API_KEY"]
    query = "q=#{uri_escaped_address}&api_key=#{api_key}"

    api_call_helper = ApiCallHelper.new(base_url: BASE_COORDINATES_ENDPOINT)
    response = api_call_helper.make_get_call(path: COORDINATES_PATH, query: query)

    if response.blank?
      puts "Received a blank response from geocode"
      return nil
    end

    first_response = response[0] # Geocode returns an array of results, we just care for the first one
    # If this was real code this might be something we would want to warn the user about, or display all results

    latitude = first_response.dig("lat")
    longitude = first_response.dig("lon")

    if latitude.blank? || longitude.blank?
      puts "Did not properly receive latitude or longitude to get forecast info"
      return nil
    end

    {
      latitude: latitude,
      longitude: longitude,
      zip: first_response.dig("address", "postcode")
    }
  end

  def self.get_forecast_info(location:)
    if location[:zip].present?
      from_cache = Rails.cache.exist?(location[:zip])
      forecast = Rails.cache.fetch(location[:zip], expires_in: 10.minutes, race_condition_ttl: 10.seconds) do
        fetch_from_open_meteo(latitude: location[:latitude], longitude: location[:longitude])
      end
      return forecast.merge("from_cache" => from_cache)
    end

    # Backup if we were not able to get the zip
    forecast = fetch_from_open_meteo(latitude: location[:latitude], longitude: location[:longitude])
    forecast.merge("from_cache" => false)
  end

  def self.fetch_from_open_meteo(latitude:, longitude:)
    query = "latitude=#{latitude}&longitude=#{longitude}"
    query += "&daily=#{DAILY_REQUESTED_DATA.join(',')}"
    query += "&current=#{CURRENT_REQUESTED_DATA.join(',')}"
    query += "&timezone=auto"

    api_call_helper = ApiCallHelper.new(base_url: BASE_WEATHER_ENDPOINT)
    api_call_helper.make_get_call(path: WEATHER_PATH, query: query)
  end
end
