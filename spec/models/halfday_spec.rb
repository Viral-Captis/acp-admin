require 'rails_helper'

describe Halfday do
  it_behaves_like 'bulk_dates_insert'

  it 'validates participants_limit to be at least 1' do
    halfday = Halfday.new(participants_limit: 0)
    expect(halfday).not_to have_valid(:participants_limit)

    halfday = Halfday.new(participants_limit: nil)
    expect(halfday).to have_valid(:participants_limit)
  end

  it 'creates an halfday without preset' do
    halfday = Halfday.new(
      date: '2018-03-24',
      start_time: Time.zone.parse('8:30'),
      end_time: Time.zone.parse('12:00'),
      place: 'Thielle',
      place_url: 'https://goo.gl/maps/xSxmiYRhKWH2',
      activity: 'Aide aux champs',
      participants_limit: 3,
      description: 'Venez nombreux!')

    expect(halfday.preset_id).to be_nil
    expect(halfday.places['fr']).to eq 'Thielle'

    halfday.save!

    expect(halfday.start_time).to eq Time.zone.parse('2018-03-24 8:30')
    expect(halfday.end_time).to eq Time.zone.parse('2018-03-24 12:00')
  end

  it 'creates an halfday with preset' do
    preset = HalfdayPreset.create!(
      place: 'Thielle',
      place_url: 'https://goo.gl/maps/xSxmiYRhKWH2',
      activity: 'Aide aux champs')
    halfday = Halfday.new(
      date: '2018-03-24',
      start_time: Time.zone.parse('8:30'),
      end_time: Time.zone.parse('12:00'),
      preset_id: preset.id)

    expect(halfday.preset_id).to be_present
    expect(halfday.places['fr']).to eq 'preset'
    expect(halfday.place_urls['de']).to eq 'preset'
    expect(halfday.activities['xx']).to eq 'preset'

    halfday.save!

    h = Halfday.find(halfday.id)
    expect(h.place).to eq 'Thielle'
    expect(h.place_url).to eq 'https://goo.gl/maps/xSxmiYRhKWH2'
    expect(h.activity).to eq  'Aide aux champs'
  end

  describe '#period' do
    it 'does not pad hours' do
      halfday = Halfday.new(
        date: '2018-03-24',
        start_time: Time.zone.parse('8:30'),
        end_time: Time.zone.parse('12:00'))

      expect(halfday.period).to eq '8:30-12:00'
    end
  end
end
