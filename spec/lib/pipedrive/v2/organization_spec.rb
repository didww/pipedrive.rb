# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pipedrive::V2::Organization do
  subject { described_class.new(access_token: 'token', domain_url: 'https://api.pipedrive.com') }

  describe '#entity_name' do
    subject { super().entity_name }

    it { is_expected.to eq('organizations') }
  end

  describe '#build_url' do
    it 'serves the resource from v2' do
      expect(subject.build_url([:get])).to eq('/api/v2/organizations')
    end
  end

  describe '#chunk' do
    it 'gets the v2 path with an ids filter' do
      stub = stub_request(:get, 'https://api.pipedrive.com/api/v2/organizations?ids=1,2&limit=2')
             .to_return(status: 200, body: { success: true, data: [] }.to_json, headers: {})

      subject.chunk(ids: '1,2', limit: 2)

      expect(stub).to have_been_requested
    end
  end

  describe '#find_by_name' do
    it 'refuses, since v2 searches with /search rather than /find' do
      expect { subject.find_by_name('Acme') }.to raise_error(NotImplementedError, /find_by_name/)
    end
  end
end
