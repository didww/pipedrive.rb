# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pipedrive::Base do
  subject { described_class.new(access_token: 'token', domain_url: 'https://api.pipedrive.com') }

  describe '#entity_name' do
    subject { super().entity_name }

    it { is_expected.to eq described_class.name.split('::')[-1].downcase.pluralize }
  end

  describe '#build_url' do
    it 'serves the resource from v1 by default' do
      expect(subject.build_url([:get])).to eq('/v1/bases')
    end

    it 'appends the id' do
      expect(subject.build_url([:get, 12])).to eq('/v1/bases/12')
    end
  end

  context '#faraday_options' do
    subject { super().faraday_options }

    it 'authenticates with the access token against the company domain' do
      expect(subject).to eq(
        url: 'https://api.pipedrive.com',
        headers: {
          authorization: 'Bearer token',
          accept: 'application/json',
          content_type: 'application/json',
          user_agent: "Pipedrive Ruby Client v#{::Pipedrive::VERSION}"
        }
      )
    end
  end

  context '::connection' do
    subject { super().connection }

    it { is_expected.to be_kind_of(::Faraday::Connection) }
  end

  describe '#failed_response' do
    subject { super().failed_response(res) }

    let(:res) { double('res', body: body) }

    context 'with a body the json middleware parsed' do
      let(:body) { ::Hashie::Mash.new(error: 'Moved') }

      it { is_expected.to eq(::Hashie::Mash.new(error: 'Moved', success: false)) }
    end

    context 'with a body it did not parse' do
      let(:body) { '<html>Moved</html>' }

      it { is_expected.to eq(::Hashie::Mash.new(success: false)) }
    end
  end

  describe '#make_api_call' do
    it 'faileds no method' do
      expect { subject.make_api_call(test: 'foo') }.to raise_error('method param missing')
    end

    context 'without id' do
      it 'calls :get' do
        stub_request(:get, 'https://api.pipedrive.com/v1/bases').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:get).with('/v1/bases', {}).and_call_original
        expect(subject.make_api_call(:get))
      end

      it 'calls :post' do
        stub_request(:post, 'https://api.pipedrive.com/v1/bases').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:post).with('/v1/bases', { test: 'bar' }.to_json).and_call_original
        expect(subject.make_api_call(:post, test: 'bar'))
      end

      it 'calls :put' do
        stub_request(:put, 'https://api.pipedrive.com/v1/bases').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:put).with('/v1/bases', { test: 'bar' }.to_json).and_call_original
        expect(subject.make_api_call(:put, test: 'bar'))
      end

      it 'uses field_selector properly' do
        stub_request(:get, 'https://api.pipedrive.com/v1/bases:(a,b,c)').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:get)
          .with('/v1/bases:(a,b,c)', {}).and_call_original
        expect(subject.make_api_call(:get, fields_to_select: %w[a b c]))
      end

      it 'does not use field_selector if it empty' do
        stub_request(:get, 'https://api.pipedrive.com/v1/bases').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:get)
          .with('/v1/bases', {}).and_call_original
        expect(subject.make_api_call(:get, fields_to_select: []))
      end

      it 'retries if Errno::ETIMEDOUT' do
        stub_request(:get, 'https://api.pipedrive.com/v1/bases').to_return(status: 200, body: {}.to_json, headers: {})
        connection = subject.connection
        allow(subject).to receive(:connection).and_return(connection)
        allow(connection).to receive(:get)
          .with('/v1/bases', {}).and_raise(Errno::ETIMEDOUT)
        expect(connection).to receive(:get)
          .with('/v1/bases', {}).and_call_original
        expect(subject.make_api_call(:get, fields_to_select: []))
      end
    end

    context 'with id' do
      it 'calls :get' do
        stub_request(:get, 'https://api.pipedrive.com/v1/bases/12').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:get).with('/v1/bases/12', {}).and_call_original
        expect(subject.make_api_call(:get, 12))
      end

      it 'calls :post' do
        stub_request(:post, 'https://api.pipedrive.com/v1/bases/13').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:post).with('/v1/bases/13', { test: 'bar' }.to_json).and_call_original
        expect(subject.make_api_call(:post, 13, test: 'bar'))
      end

      it 'calls :put' do
        stub_request(:put, 'https://api.pipedrive.com/v1/bases/14').to_return(status: 200, body: {}.to_json, headers: {})
        expect_any_instance_of(::Faraday::Connection).to receive(:put).with('/v1/bases/14', { test: 'bar' }.to_json).and_call_original
        expect(subject.make_api_call(:put, 14, test: 'bar'))
      end
    end

    it 'calls Hashie::Mash if return empty string' do
      stub_request(:get, 'https://api.pipedrive.com/v1/bases').to_return(status: 200, body: '', headers: {})
      expect(::Hashie::Mash).to receive(:new).with(success: true).and_call_original
      expect(subject.make_api_call(:get))
    end

    it 'raises on a failed status, since the raise_error middleware precedes #failed_response' do
      stub_request(:get, 'https://api.pipedrive.com/v1/bases').to_return(status: 400, body: '', headers: {})
      expect { subject.make_api_call(:get) }.to raise_error(::Faraday::BadRequestError)
    end
  end
end
