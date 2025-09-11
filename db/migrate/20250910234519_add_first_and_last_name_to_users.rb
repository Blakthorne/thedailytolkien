class AddFirstAndLastNameToUsers < ActiveRecord::Migration[8.0]
  def change
    # Add new columns
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string

    # Split existing names into first and last name
    reversible do |dir|
      dir.up do
        User.reset_column_information
        User.find_each do |user|
          if user.name.present?
            name_parts = user.name.strip.split(' ')
            first_name = name_parts.first
            last_name = name_parts.length > 1 ? name_parts[1..-1].join(' ') : ''

            user.update_columns(
              first_name: first_name,
              last_name: last_name.present? ? last_name : 'User'
            )
          else
            # Handle users with null or empty names
            user.update_columns(
              first_name: 'User',
              last_name: 'Name'
            )
          end
        end
      end

      dir.down do
        User.reset_column_information
        User.find_each do |user|
          full_name = "#{user.first_name} #{user.last_name}".strip
          user.update_columns(name: full_name)
        end
      end
    end

    # Add constraints after data migration
    change_column_null :users, :first_name, false
    change_column_null :users, :last_name, false
  end
end
