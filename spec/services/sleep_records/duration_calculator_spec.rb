# spec/services/sleep_records/duration_calculator_spec.rb
require 'rails_helper'

RSpec.describe SleepRecords::DurationCalculator do
  describe '.calculate_minutes' do
    context 'with valid start and end times' do
      it 'calculates duration in minutes for a standard sleep' do
        start_time = Time.current - 8.hours
        end_time = Time.current

        duration = described_class.calculate_minutes(start_time, end_time)

        expect(duration).to eq(8 * 60) # 8 hours = 480 minutes
      end

      it 'calculates duration for short sleeps' do
        start_time = Time.current - 30.minutes
        end_time = Time.current

        duration = described_class.calculate_minutes(start_time, end_time)

        expect(duration).to eq(30) # 30 minutes
      end

      it 'calculates duration for long sleeps' do
        start_time = Time.current - 12.hours
        end_time = Time.current

        duration = described_class.calculate_minutes(start_time, end_time)

        expect(duration).to eq(12 * 60) # 12 hours = 720 minutes
      end

      it 'handles non-round hour durations' do
        start_time = Time.current - 7.hours - 23.minutes
        end_time = Time.current

        duration = described_class.calculate_minutes(start_time, end_time)

        expect(duration).to eq((7 * 60) + 23) # 7 hours 23 minutes = 443 minutes
      end

      it 'handles millisecond precision' do
        start_time = Time.current - 6.hours - 30.5.minutes
        end_time = Time.current

        duration = described_class.calculate_minutes(start_time, end_time)

        # Should round to nearest minute
        expect(duration).to eq((6 * 60) + 31) # 6 hours 31 minutes = 391 minutes
      end
    end

    context 'with invalid inputs' do
      it 'returns nil when start_time is nil' do
        expect(described_class.calculate_minutes(nil, Time.current)).to be_nil
      end

      it 'returns nil when end_time is nil' do
        expect(described_class.calculate_minutes(Time.current, nil)).to be_nil
      end

      it 'returns nil when end_time is before start_time' do
        start_time = Time.current
        end_time = start_time - 1.hour

        expect(described_class.calculate_minutes(start_time, end_time)).to be_nil
      end

      it 'returns nil when times are equal' do
        time = Time.current
        expect(described_class.calculate_minutes(time, time)).to be_nil
      end
    end
  end

  describe '.for_sleep_record' do
    context 'with a completed sleep record' do
      let(:sleep_record) { build(:sleep_record, start_time: 8.hours.ago, end_time: Time.current) }

      it 'calculates duration from the sleep record times' do
        duration = described_class.for_sleep_record(sleep_record)
        expected = ((sleep_record.end_time - sleep_record.start_time) / 60).to_i

        expect(duration).to eq(expected)
      end
    end

    context 'with an in-progress sleep record' do
      let(:sleep_record) { build(:sleep_record, start_time: 4.hours.ago, end_time: nil) }

      it 'returns nil' do
        expect(described_class.for_sleep_record(sleep_record)).to be_nil
      end

      it 'calculates current duration when current time is provided' do
        duration = described_class.for_sleep_record(sleep_record, use_current_time: true)
        expected = ((Time.current - sleep_record.start_time) / 60).to_i

        expect(duration).to be_within(1).of(expected)
      end
    end

    context 'with an invalid sleep record' do
      it 'returns nil when record is nil' do
        expect(described_class.for_sleep_record(nil)).to be_nil
      end
    end
  end
end
