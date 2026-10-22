# frozen_string_literal: true

module Pipedrive
  module Operations
    # API v2 pages with an opaque cursor instead of v1's numeric start offset, and reports the end of
    # the collection by returning no next_cursor.
    # https://pipedrive.readme.io/docs/core-api-concepts-pagination
    module CursorPagination
      extend ActiveSupport::Concern

      def follow_pagination(method, args, params, &block)
        params = params.to_h.symbolize_keys
        cursor = params.delete(:cursor)
        seen = []
        loop do
          res = __send__(method, *args, cursor ? params.merge(cursor: cursor) : params)
          break unless res.try(:data)

          res.data.each(&block)
          seen << cursor
          cursor = res.try(:additional_data).try(:next_cursor)
          # A cursor Pipedrive has already served would otherwise re-request the same page forever.
          break if cursor.blank? || seen.include?(cursor)
        end
      end
    end
  end
end
