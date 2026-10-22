# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pipedrive::V2::Person do
  subject { described_class.new(access_token: 'token', domain_url: 'https://api.pipedrive.com') }

  describe '#entity_name' do
    subject { super().entity_name }

    it { is_expected.to eq('persons') }
  end

  describe '#build_url' do
    it 'serves the resource from v2' do
      expect(subject.build_url([:get])).to eq('/api/v2/persons')
    end

    it 'appends the id' do
      expect(subject.build_url([:get, 12])).to eq('/api/v2/persons/12')
    end

    it 'ignores the v1-only field selector' do
      expect(subject.build_url([:get], %w[id name])).to eq('/api/v2/persons')
    end
  end

  describe '#chunk' do
    it 'gets the v2 path with the cursor' do
      stub = stub_request(:get, 'https://api.pipedrive.com/api/v2/persons?limit=500&cursor=abc')
             .to_return(
               status: 200,
               body: { success: true, data: [], additional_data: { next_cursor: nil } }.to_json,
               headers: {}
             )

      subject.chunk(limit: 500, cursor: 'abc')

      expect(stub).to have_been_requested
    end
  end

  describe '#each' do
    it 'follows the cursor rather than the v1 start offset' do
      expect(subject).to receive(:chunk).with({}).and_return(
        ::Hashie::Mash.new(data: [1, 2], success: true, additional_data: { next_cursor: 'eyJpZCI6Mn0' })
      )
      expect(subject).to receive(:chunk).with({ cursor: 'eyJpZCI6Mn0' }).and_return(
        ::Hashie::Mash.new(data: [3, 4], success: true, additional_data: { next_cursor: nil })
      )

      expect { |b| subject.each(&b) }.to yield_successive_args(1, 2, 3, 4)
    end
  end

  describe '#find_by_name' do
    it 'refuses, since v2 searches with /search rather than /find' do
      expect { subject.find_by_name('Bob') }.to raise_error(NotImplementedError, /find_by_name/)
    end
  end
end
