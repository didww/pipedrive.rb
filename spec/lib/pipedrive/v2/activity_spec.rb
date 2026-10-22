# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pipedrive::V2::Activity do
  subject { described_class.new(access_token: 'token', domain_url: 'https://api.pipedrive.com') }

  describe '#entity_name' do
    subject { super().entity_name }

    it { is_expected.to eq('activities') }
  end

  describe '#build_url' do
    it 'serves the resource from v2' do
      expect(subject.build_url([:post])).to eq('/api/v2/activities')
    end

    it 'ignores the v1-only field selector' do
      expect(subject.build_url([:get], %w[id subject])).to eq('/api/v2/activities')
    end
  end

  describe '#create' do
    it 'posts to the v2 path' do
      stub = stub_request(:post, 'https://api.pipedrive.com/api/v2/activities')
             .with(body: { subject: 'Call' }.to_json)
             .to_return(status: 200, body: { success: true, data: { id: 7 } }.to_json, headers: {})

      subject.create(subject: 'Call')

      expect(stub).to have_been_requested
    end
  end

  describe '#update' do
    it 'patches the v2 path, where v1 used put' do
      stub = stub_request(:patch, 'https://api.pipedrive.com/api/v2/activities/7')
             .with(body: { subject: 'Call' }.to_json)
             .to_return(status: 200, body: { success: true, data: { id: 7 } }.to_json, headers: {})

      subject.update(7, subject: 'Call')

      expect(stub).to have_been_requested
    end
  end

  describe '#delete_all' do
    it 'refuses, since v2 deletes one record at a time' do
      expect { subject.delete_all }.to raise_error(NotImplementedError, /delete_all/)
    end
  end
end
