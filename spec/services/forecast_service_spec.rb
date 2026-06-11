require 'rails_helper'

RSpec.describe ForecastService do
  describe '.get_forecast' do
    let(:address) { }
    let(:helper_mock) { instance_double(ApiCallHelper) }
    let(:forecast_response) { { "just_checking_its_not_emtpy" => Faker::Alphanumeric.alpha(number: 5) } }
    let(:geocode_response) { nil }
    let(:zip) { Faker::Number.number(digits: 5).to_s }

    before do
      allow(ApiCallHelper).to receive(:new).and_return(helper_mock)
      allow(helper_mock).to receive(:make_get_call).with(path: ForecastService::COORDINATES_PATH, query: anything).and_return(geocode_response)
      allow(helper_mock).to receive(:make_get_call).with(path: ForecastService::WEATHER_PATH, query: anything).and_return(forecast_response)
    end

    shared_examples :returns_forecast do
      it 'succeeded' do
        result = ForecastService.get_forecast(address: address)
        expect(result).not_to be_blank
      end
    end

    shared_examples :returns_blank do
      it 'failed' do
        result = ForecastService.get_forecast(address: address)
        expect(result).to be_blank
      end
    end

    shared_examples :makes_geocode_api_call do
      it 'make api call' do
        ForecastService.get_forecast(address: address)
        expect(ApiCallHelper).to have_received(:new).with(base_url: ForecastService::BASE_COORDINATES_ENDPOINT)
      end
    end

    shared_examples :does_not_make_geocode_api_call do
      it 'does not make api call' do
        ForecastService.get_forecast(address: address)
        expect(ApiCallHelper).not_to have_received(:new).with(base_url: ForecastService::BASE_COORDINATES_ENDPOINT)
      end
    end

    shared_examples :makes_weather_api_call do
      it 'make api call' do
        ForecastService.get_forecast(address: address)
        expect(ApiCallHelper).to have_received(:new).with(base_url: ForecastService::BASE_WEATHER_ENDPOINT)
      end
    end

    shared_examples :does_not_make_weather_api_call do
      it 'does not make api call' do
        ForecastService.get_forecast(address: address)
        expect(ApiCallHelper).not_to have_received(:new).with(base_url: ForecastService::BASE_WEATHER_ENDPOINT)
      end
    end

    shared_examples :result_shows_it_was_not_cached do
      it 'include from_cache false' do
        result = ForecastService.get_forecast(address: address)
        expect(result["from_cache"]).to be(false)
      end
    end

    shared_examples :result_shows_it_was_cached do
      it 'include from_cache true' do
        result = ForecastService.get_forecast(address: address)
        expect(result["from_cache"]).to be(true)
      end
    end

    context 'when receiving empty address' do
      it_behaves_like :returns_blank
      it_behaves_like :does_not_make_weather_api_call
      it_behaves_like :does_not_make_geocode_api_call
    end

    context 'when unexpected error occurs' do
      before do
        allow(helper_mock).to receive(:make_get_call).and_raise(StandardError)
      end

      it_behaves_like :returns_blank
      it_behaves_like :does_not_make_weather_api_call
      it_behaves_like :does_not_make_geocode_api_call
    end

    context 'when receiving a valid address' do
      let(:address) { "CA 95014" } # Apple zip

      context 'receive empty coordinates response' do
        it_behaves_like :returns_blank
        it_behaves_like :makes_geocode_api_call
        it_behaves_like :does_not_make_weather_api_call
      end

      context 'response is missing longitude' do
        let(:geocode_response) do
          [ {
            "lat" => Faker::Number.number(digits: 2),
            "address" => { "postcode" => zip }
          } ]
        end

        it_behaves_like :returns_blank
        it_behaves_like :makes_geocode_api_call
        it_behaves_like :does_not_make_weather_api_call
      end

      context 'response is missing latitude' do
        let(:geocode_response) do
          [ {
            "lon" => Faker::Number.number(digits: 2),
            "address" => { "postcode" => zip }
          } ]
        end

        it_behaves_like :returns_blank
        it_behaves_like :makes_geocode_api_call
        it_behaves_like :does_not_make_weather_api_call
      end

      context 'response is missing zip' do
        let(:geocode_response) do
          [ {
            "lat" => Faker::Number.number(digits: 2),
            "lon" => Faker::Number.number(digits: 2)
          } ]
        end

        it_behaves_like :returns_forecast
        it_behaves_like :makes_geocode_api_call
        it_behaves_like :makes_weather_api_call
        it_behaves_like :result_shows_it_was_not_cached
      end

      context 'response includes all data' do
        let(:geocode_response) do
          [ {
            "lat" => Faker::Number.number(digits: 2),
            "lon" => Faker::Number.number(digits: 2),
            "address" => { "postcode" => zip }
          } ]
        end

        context 'zip is cached' do
          before do
            Rails.cache.write(zip, forecast_response)
          end

          it_behaves_like :returns_forecast
          it_behaves_like :makes_geocode_api_call
          it_behaves_like :does_not_make_weather_api_call
          it_behaves_like :result_shows_it_was_cached
        end

        context 'zip is not cached' do
          it_behaves_like :returns_forecast
          it_behaves_like :makes_geocode_api_call
          it_behaves_like :makes_weather_api_call
          it_behaves_like :result_shows_it_was_not_cached
        end
      end
    end
  end
end
