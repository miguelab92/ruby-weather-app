require 'rails_helper'

RSpec.describe ForecastService do
  describe '.get_forecast' do
    let(:address) {}

    shared_context :returns_blank do
      it 'failed' do
        result = ForecastService.get_forecast(address: address)
        expect(result).to be_blank
      end
    end

    context 'when receiving empty address' do
      it_behaves_like :returns_blank
    end

    context 'when receiving a valid address' do
      
    end
  end
end
