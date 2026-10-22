# frozen_string_literal: true

module Pipedrive
  module V2
    # What it means to be an API v2 resource: the /api/v2 prefix, cursor paging, and the v1-only
    # operations that v2 does not implement.
    # https://pipedrive.readme.io/docs/pipedrive-api-v2-migration-guide
    module Resource
      extend ActiveSupport::Concern
      include ::Pipedrive::Operations::CursorPagination

      # v1 searched with GET /{entity}/find; v2 replaced it with /{entity}/search, whose parameters
      # and response envelope both differ, so it needs its own implementation rather than inheritance.
      def find_by_name(*)
        raise NotImplementedError, "#{self.class} does not support find_by_name; v2 searches with /search"
      end

      # v1 deleted in bulk with DELETE /{entity}?ids=; v2 only deletes one record at a time.
      def delete_all
        raise NotImplementedError, "#{self.class} does not support delete_all; v2 deletes one record at a time"
      end

      class_methods do
        def api_version
          :v2
        end
      end

      private

      # v2 updates with PATCH, where v1 used PUT.
      def update_http_method
        :patch
      end
    end
  end
end
