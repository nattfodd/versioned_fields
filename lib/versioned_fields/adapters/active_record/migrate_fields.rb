# frozen_string_literal: true

module VersionedFields
  module Adapters
    module ActiveRecord
      module MigrateFields
        # Those methods are included into model class
        def migrate_fields!
          for_each_migration do |field, next_version|
            migration =
              Migrations.migration_for(self.class, field, next_version)

            # Call migration & update field's version
            migration_params =
              Migrations::Params.new(field: field, version: next_version)
            new_value = instance_exec(migration_params, &migration)
            public_send("#{field}=",         new_value)
            public_send("#{field}_version=", next_version)
          end

          save(validate: false)
        end
        private :migrate_fields!

        def for_each_migration
          Migrations.migrations[self.class].each do |field, migration_data|
            latest_version  = migration_data.latest_version
            current_version = public_send("#{field}_version")
            raise MissingFieldVersion.new(field, self) unless current_version

            current_version = current_version.to_i
            next if current_version == latest_version

            migration_data.versions_above(current_version).each do |version|
              yield field, version
            end
          end
        end
        private :for_each_migration
      end
    end
  end
end
