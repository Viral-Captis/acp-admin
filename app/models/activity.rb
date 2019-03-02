class Activity < ActiveRecord::Base
  include TranslatedAttributes
  include HasFiscalYearScopes
  include BulkDatesInsert
  include ActivityNaming

  attr_reader :preset_id, :preset

  serialize :start_time, Tod::TimeOfDay
  serialize :end_time, Tod::TimeOfDay

  translated_attributes :place, :place_url, :activity, :description

  has_many :participations, class_name: 'ActivityParticipation'

  scope :coming, -> { where('activities.date > ?', Date.current) }
  scope :past, -> { where('activities.date <= ?', Date.current) }
  scope :past_current_year, -> {
    where('activities.date < ? AND activities.date >= ?', Date.current, Current.fy_range.min)
  }

  validates :start_time, :end_time, presence: true
  validates :participants_limit,
    numericality: { greater_than_or_equal_to: 1, allow_nil: true }
  validate :end_time_must_be_greather_than_start_time

  def self.available_for(member)
    where('date >= ?', Current.acp.activity_availability_limit_in_days.days.from_now)
      .includes(:participations)
      .reject { |hd| hd.participant?(member) || hd.full? }
      .sort_by { |hd| "#{hd.date}#{hd.period}" }
  end

  def self.available
    where('date >= ?', Current.acp.activity_availability_limit_in_days.days.from_now)
      .includes(:participations)
      .reject(&:full?)
      .sort_by { |hd| "#{hd.date}#{hd.period}" }
  end

  def full?
    participants_limit && missing_participants_count.zero?
  end

  def participant?(member)
    participations.map(&:member_id).include?(member.id)
  end

  def missing_participants_count
    participants_limit &&
      participants_limit - participations.map(&:participants_count).sum
  end

  def name
    [I18n.l(date, format: :medium), place, period].join(', ')
  end

  def period
    [start_time, end_time].map { |t| t.strftime('%-k:%M') }.join('-')
  end

  %i[places place_urls activities].each do |attr|
    define_method attr do
      @preset ? Hash.new('preset') : self[attr]
    end
  end

  def preset_id=(preset_id)
    @preset_id = preset_id
    if @preset = ActivityPreset.find_by(id: preset_id)
      self.places = @preset.places
      self.place_urls = @preset.place_urls
      self.activities = @preset.activities
    end
  end

  private

  def end_time_must_be_greather_than_start_time
    if end_time && start_time && end_time <= start_time
      errors.add(:end_time, :invalid)
    end
  end
end
