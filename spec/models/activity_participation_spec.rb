require 'rails_helper'

describe ActivityParticipation do
  let(:member) { create(:member) }
  let(:admin) { create(:admin) }

  def last_email
    ActionMailer::Base.deliveries.last
  end

  describe 'validations' do
    it 'validates activity participants limit' do
      activity = create(:activity, participants_limit: 3)
      create(:activity_participation, activity: activity, participants_count: 1)
      participation = build(:activity_participation, activity: activity.reload, participants_count: 3)
      expect(participation).not_to have_valid(:participants_count)
    end

    it 'validates activity participants limit when many participations' do
      activity1 = create(:activity, participants_limit: 3)
      activity2 = create(:activity, participants_limit: 10)
      create(:activity_participation, activity: activity1, participants_count: 1)
      participation = build(:activity_participation,
        activity: nil,
        activity_ids: [activity1.id, activity2.id],
        participants_count: 3)
      participation.save

      expect(participation.errors[:participants_count]).to eq ['doit être inférieur ou égal à 2']
    end

    it 'does not validates activity participants limit when update' do
      activity = create(:activity, participants_limit: 3)
      participation = create(:activity_participation, activity: activity, participants_count: 3)
      participation.reload

      participation.update(participants_count: 2)

      expect(participation).to have_valid(:participants_count)
    end

    it 'validates carpooling phone and city presence when carpooling is checked' do
      activity = create(:activity, participants_limit: 3)
      participation = build(:activity_participation,
        activity: activity,
        participants_count: 1,
        carpooling: '1')

      expect(participation).not_to have_valid(:carpooling_phone)
      expect(participation).not_to have_valid(:carpooling_city)
    end

    it 'validates carpooling phone format when carpooling is checked' do
      activity = create(:activity, participants_limit: 3)
      participation = build(:activity_participation,
        activity: activity,
        participants_count: 1,
        carpooling_phone: 'foo',
        carpooling: '1')

      expect(participation).not_to have_valid(:carpooling_phone)
    end
  end

  describe '#validate!' do
    it 'sets states column' do
      activity = create(:activity, date: 3.days.ago)
      participation = create(:activity_participation,
        activity: activity,
        review_sent_at: Time.current,
        rejected_at: Time.current)

      expect(participation.validate!(admin)).to eq true

      expect(participation).to have_attributes(
        state: 'validated',
        validated_at: Time,
        validator_id: admin.id,
        rejected_at: nil,
        review_sent_at: nil)
    end

    it 'does not validate already validated activity participations' do
      activity = create(:activity, date: 3.days.ago)
      participation = create(:activity_participation, :validated, activity: activity)

      expect(participation.validate!(admin)).to be_nil
    end
  end

  describe '#reject!' do
    it 'sets states column' do
      activity = create(:activity, date: 3.days.ago)
      participation = create(:activity_participation,
        activity: activity,
        review_sent_at: Time.current,
        validated_at: Time.current)

      expect(participation.reject!(admin)).to eq true

      expect(participation).to have_attributes(
        state: 'rejected',
        rejected_at: Time,
        validator_id: admin.id,
        validated_at: nil,
        review_sent_at: nil)
    end

    it 'does not reject already rejected activity participations' do
      activity = create(:activity, date: 3.days.ago)
      participation = create(:activity_participation, :rejected, activity: activity)

      expect(participation.reject!(admin)).to be_nil
    end
  end

  describe '#carpooling' do
    let(:participation) { build(:activity_participation, member: member) }

    it 'resets carpooling phone and city if carpooling = 0' do
      participation.carpooling = '0'
      participation.carpooling_phone = '077 123 41 12'
      participation.carpooling_city = 'La Chaux-de-Fonds'
      participation.save
      expect(participation.carpooling_phone).to be_nil
      expect(participation.carpooling_city).to be_nil
    end
  end

  describe '#destroyable?' do
    it 'always returns true by the default' do
      activity = create(:activity, date: 2.days.from_now)
      participation = create(:activity_participation, activity: activity, created_at: 25.hours.ago)
      expect(participation).to be_destroyable
    end

    it 'returns true when a deletion deadline is set and creation is in the last 24h' do
      Current.acp.update!(activity_participation_deletion_deadline_in_days: 30)
      activity = create(:activity, date: 29.days.from_now)
      participation = create(:activity_participation, activity: activity, created_at: 20.hours.ago)

      expect(participation).to be_destroyable
    end

    it 'returns false when a deletion deadline is set and creation has been done more that 24h ago' do
      Current.acp.update!(activity_participation_deletion_deadline_in_days: 30)
      activity = create(:activity, date: 29.days.from_now)
      participation = create(:activity_participation, activity: activity, created_at: 25.hours.ago)

      expect(participation).not_to be_destroyable
    end
  end

  describe '#reminderable?' do
    it 'is reminderable when activity participations is in less than two weeks' do
      activity = create(:activity, date: 2.weeks.from_now - 1.hour)
      participation = create(:activity_participation,
        activity: activity,
        created_at: 2.months.ago,
        latest_reminder_sent_at: nil)
      expect(participation).to be_reminderable
    end

    it 'is not reminderable when activity participations is in less than two weeks but already reminded' do
      activity = create(:activity, date: 2.weeks.from_now - 1.hour)
      participation = create(:activity_participation,
        activity: activity,
        created_at: 2.months.ago,
        latest_reminder_sent_at: Time.current)
      expect(participation).not_to be_reminderable
    end

    it 'is not reminderable when activity participations is in more than two weeks' do
      activity = create(:activity, date: 15.days.from_now)
      participation = create(:activity_participation,
        activity: activity,
        created_at: 2.months.ago,
        latest_reminder_sent_at: nil)
      expect(participation).not_to be_reminderable
    end

    it 'is reminderable when participation has been created less than a day ago' do
      activity = create(:activity, date: 2.weeks.from_now - 1.hour)
      participation = create(:activity_participation,
        activity: activity,
        created_at: 1.day.ago,
        latest_reminder_sent_at: nil)
      expect(participation).to be_reminderable
    end

    it 'is reminderable when activity participations is in less than three days' do
      activity = create(:activity, date: 3.days.from_now - 1.hour)
      participation = create(:activity_participation,
        activity: activity,
        created_at: 2.months.ago,
        latest_reminder_sent_at: 2.weeks.ago)
      expect(participation).to be_reminderable
    end

    it 'is reminderable when activity participations is in less than three days and never reminded' do
      activity = create(:activity, date: 3.days.from_now - 1.hour)
      participation = create(:activity_participation,
        activity: activity,
        created_at: 6.days.ago,
        latest_reminder_sent_at: nil)
      expect(participation).to be_reminderable
    end

    it 'is not reminderable when activity participations is in less than three days but already reminded' do
      activity = create(:activity, date: 3.days.from_now - 1.hour)
      participation = create(:activity_participation,
        activity: activity,
        created_at: 2.months.ago,
        latest_reminder_sent_at: 6.days.ago)
      expect(participation).not_to be_reminderable
    end

    it 'is not reminderable when activity participations is in less than three days but already reminded (now)' do
      activity = create(:activity, date: 3.days.from_now - 1.hour)
      participation = create(:activity_participation,
        activity: activity,
        created_at: 2.months.ago,
        latest_reminder_sent_at: Time.current)
      expect(participation).not_to be_reminderable
    end

    it 'is not reminderable when activity participations have past' do
      activity = create(:activity, date: 1.day.ago)
      participation = create(:activity_participation,
        activity: activity,
        created_at: 2.months.ago,
        latest_reminder_sent_at: nil)
      expect(participation).not_to be_reminderable
    end
  end

  it 'updates membership activity_participations_accepted' do
    member = create(:member)
    membership = create(:membership, member: member)

    participation = build(:activity_participation,
      activity: create(:activity, date: 1.day.ago),
      member: member,
      participants_count: 2)

    expect { participation.save! }
      .to change { membership.reload.activity_participations_accepted }.by(2)
    expect { participation.reject!(create(:admin)) }
      .to change { membership.reload.activity_participations_accepted }.by(-2)
  end
end
