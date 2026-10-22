# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Pipedrive::Operations::CursorPagination do
  subject do
    Class.new(::Pipedrive::Base) do
      include ::Pipedrive::Operations::Read
      include ::Pipedrive::Operations::CursorPagination
    end.new(access_token: 'token', domain_url: 'https://api.pipedrive.com')
  end

  def page(data, next_cursor = nil)
    ::Hashie::Mash.new(data: data, success: true, additional_data: { next_cursor: next_cursor })
  end

  describe '#each' do
    it 'sends no cursor on the first page' do
      expect(subject).to receive(:chunk).with({}).and_return(page([1]))
      expect { |b| subject.each(&b) }.to yield_successive_args(1)
    end

    it 'passes the next_cursor on to the following page' do
      expect(subject).to receive(:chunk).with({}).and_return(page([1], 'c1'))
      expect(subject).to receive(:chunk).with({ cursor: 'c1' }).and_return(page([2], 'c2'))
      expect(subject).to receive(:chunk).with({ cursor: 'c2' }).and_return(page([3]))

      expect { |b| subject.each(&b) }.to yield_successive_args(1, 2, 3)
    end

    it 'stops on a blank next_cursor rather than on a short page' do
      expect(subject).to receive(:chunk).once.with({}).and_return(page([1, 2], ''))

      expect { |b| subject.each(&b) }.to yield_successive_args(1, 2)
    end

    it 'starts from a cursor it is given' do
      expect(subject).to receive(:chunk).with({ cursor: 'c1' }).and_return(page([1]))
      expect { |b| subject.each({ cursor: 'c1' }, &b) }.to yield_successive_args(1)
    end

    it 'takes a string-keyed cursor without duplicating the parameter' do
      expect(subject).to receive(:chunk).with({ cursor: 'c1' }).and_return(page([1]))
      expect { |b| subject.each({ 'cursor' => 'c1' }, &b) }.to yield_successive_args(1)
    end

    it 'stops when Pipedrive repeats a cursor it has already served' do
      expect(subject).to receive(:chunk).with({}).and_return(page([1], 'c1'))
      expect(subject).to receive(:chunk).once.with({ cursor: 'c1' }).and_return(page([2], 'c1'))

      expect { |b| subject.each(&b) }.to yield_successive_args(1, 2)
    end

    it 'does not yield anything when the page carries no data' do
      expect(subject).to receive(:chunk).with({}).and_return(::Hashie::Mash.new(success: true))
      expect { |b| subject.each(&b) }.to yield_successive_args
    end
  end
end
