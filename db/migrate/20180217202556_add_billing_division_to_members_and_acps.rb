class AddBillingDivisionToMembersAndAcps < ActiveRecord::Migration[5.2]
  def change
    add_column :acps, :billing_year_divisions, :integer, array: true, default: [], null: false
    add_column :members, :billing_year_division, :integer, default: 1, null: false
    remove_column :invoices, :member_billing_interval
    remove_index :invoices, column: %w[date member_id]

    # Member.with_deleted.find_each { |m| m.update_columns billing_year_division: m.billing_interval == 'quarterly' ? 4 : 1 }
  end
end
