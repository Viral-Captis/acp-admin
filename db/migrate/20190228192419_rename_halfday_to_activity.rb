class RenameHalfdayToActivity < ActiveRecord::Migration[5.2]
  def change
    rename_column :acps, :halfday_i18n_scope, :activity_i18n_scope
    rename_column :acps, :halfday_participation_deletion_deadline_in_days, :activity_participation_deletion_deadline_in_days
    rename_column :acps, :halfday_availability_limit_in_days, :activity_availability_limit_in_days
    rename_column :acps, :halfday_phone, :activity_phone

    rename_column :basket_sizes, :annual_halfday_works, :activity_demanded

    rename_table :halfdays, :activity_dates
    rename_table :halfday_presets, :activity_presets
    rename_table :halfday_participations, :activity_participations
    rename_column :activity_participations, :halfday_id, :activity_date_id

    rename_column :invoices, :paid_missing_halfday_works, :paid_missing_activity

    rename_column :memberships, :halfday_works_annual_price, :activity_annual_price_change
    rename_column :memberships, :annual_halfday_works, :activity_demanded_annualy
    rename_column :memberships, :halfday_works, :activity_demanded
    rename_column :memberships, :recognized_halfday_works, :activity_accepted
  end
end
