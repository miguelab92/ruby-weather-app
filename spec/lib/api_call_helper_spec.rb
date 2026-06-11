require 'rails_helper'

RSpec.describe ApiCallHelper do
  let(:base_url) { Faker::Internet.domain_name  }

  describe '#initialize' do
    context 'when address provided' do
      it 'properly sets @connection' do
        helper = ApiCallHelper.new(base_url: base_url)
        expect(helper.instance_variable_get(:@connection)).not_to be_nil
      end
    end
  end

  describe '#make_get_call' do
    let(:path) { '/test' }
    let(:query) { 'q=test' }
    let(:status) { 200 }
    let(:mock_response) { instance_double(Faraday::Response, status: status, body: {}) }
    let(:helper) { ApiCallHelper.new(base_url: base_url) }

    before do
      allow(helper.instance_variable_get(:@connection)).to receive(:get).and_return(mock_response)
    end

    context 'when response is 300 or higher' do
      let(:status) { 300 }

      it 'returns nil' do
        result = helper.make_get_call(path: path, query: query)
        expect(result).to be_nil
      end
    end

    context 'when query is included' do
      let(:expected_query) { "#{path}?#{query}" }

      it 'includes query in call' do
        helper.make_get_call(path: path, query: query)
        expect(helper.instance_variable_get(:@connection)).to have_received(:get).with(expected_query)
      end
    end

    context 'when query is not included' do
      let(:expected_query) { "#{path}" }

      it 'does not include query in call' do
        helper.make_get_call(path: path)
        expect(helper.instance_variable_get(:@connection)).to have_received(:get).with(expected_query)
      end
    end
  end
end
