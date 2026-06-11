require 'rails_helper'

RSpec.describe ForecastsController, type: :controller do
  describe '#index' do
    it 'displays without issue' do
      get :index

      expect(response).to have_http_status(200)
    end
  end

  describe '#show' do
    let(:params) { {} }
    let(:address) { Faker::Address.full_address }

    shared_context :redirects_to_index do
      it 'redirects to index' do
        get :show, params: params
        expect(response).to have_http_status(302)
      end
    end

    context 'does not include an address' do
      it_behaves_like :redirects_to_index
    end

    context 'includes bad params' do
      let(:params) { { bad_params: Faker::Alphanumeric.alpha(number: 10) } }

      it_behaves_like :redirects_to_index
    end

    context 'when it is a valid address' do
      let(:params) { { address: address } }
      let(:forecast) { }

      before do
        allow(ForecastService).to receive(:get_forecast).and_return(forecast)
      end

      context 'ForecastService returns bad result' do
        it_behaves_like :redirects_to_index
      end

      context 'ForecastService returns results' do
        let(:forecast) { { current_temperature: 70 } }

        it 'returns successfully' do
          get :show, params: params
          expect(response).to have_http_status(200)
        end
      end
    end
  end
end
