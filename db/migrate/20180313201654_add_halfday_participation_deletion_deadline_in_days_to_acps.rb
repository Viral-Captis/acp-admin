class AddActivityParticipationDeletionDeadlineInDaysToAcps < ActiveRecord::Migration[5.2]
  def change
    add_column :acps, :activity_participation_deletion_deadline_in_days, :integer
  end
end
