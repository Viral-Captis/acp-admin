namespace :activity_participations do
  desc 'Send halfday participations reminder emails'
  task send_reminder_emails: :environment do
    ACP.enter_each! do
      ActivityParticipation
        .coming
        .includes(:activity)
        .find_each(&:send_reminder_email)
      puts "#{Current.acp.name}: halfday participations reminder emails sent."
    end
  end
end
