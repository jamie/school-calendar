require "icalendar"

module CalSeeder
  def find(uuid)
    cal = new(uuid)
    if uuid == "018a805b-d352-76ec-9792-044d683090c2"
      seed_cal_data(cal, cal.icalendar)
    end
    cal
  end

  def seed_cal_data(cal, icalendar)
    cal.set_term(
      starts_on: Date.new(2023, 9, 4),
      ends_on: Date.new(2023, 12, 31), # Just this year
      # end_date = Date.new(2024, 6, 28),
      non_instructional_days: [
        Date.new(2023, 9, 4),
        Date.new(2023, 10, 2),
        Date.new(2023, 10, 9),
        Date.new(2023, 11, 13),

        # Christmas Break
        Date.new(2023, 12, 25),
        Date.new(2023, 12, 26),
        Date.new(2023, 12, 27),
        Date.new(2023, 12, 28),
        Date.new(2023, 12, 29),
        Date.new(2024, 1, 1),
        Date.new(2024, 1, 2),
        Date.new(2024, 1, 3),
        Date.new(2024, 1, 4),
        Date.new(2024, 1, 5),

        Date.new(2024, 2, 4),
        Date.new(2024, 2, 5),
        Date.new(2024, 2, 19),

        # Spring Break
        Date.new(2024, 3, 11),
        Date.new(2024, 3, 12),
        Date.new(2024, 3, 13),
        Date.new(2024, 3, 14),
        Date.new(2024, 3, 15),
        Date.new(2024, 3, 18),
        Date.new(2024, 3, 19),
        Date.new(2024, 3, 20),
        Date.new(2024, 3, 21),
        Date.new(2024, 3, 22),

        Date.new(2024, 3, 29),
        Date.new(2024, 4, 1),
        Date.new(2024, 4, 29),
        Date.new(2024, 5, 20),
        Date.new(2024, 6, 27),
        Date.new(2024, 6, 28)
      ]
    )

    cal.set_classes(
      [
        {block: "A", name: "Wood Work", room: "B103"},
        {block: "B", name: "Science 8", room: "C216"},
        {block: "C", name: "English 8", room: "PT02"},
        {block: "D", name: "Ph E", room: "Gym 4"}
      ]
      # TODO: move to this, and filter when building calendar
      # classes = [
      #   {
      #     block: "A",
      #     name: "Wood Work",
      #     room: "B103",
      #     teacher: "Mr. Smith",
      #     days: Date.new(2023, 9, 4)..Date.new(2023, 10, 3)
      #   },
      # ]
    )

    block_rotation = [
      nil,
      %w[A B C D], # Monday
      %w[C D A B], # Tuesday
      %w[B A D C], # Wednesday
      %w[D C B A] # Thursday
    ]
    school = {
      1 => { # Monday
        times: [[8, 30], [9, 48], [11, 34], [12, 53]],
        duration: 67,
        blocks: block_rotation[1..1].cycle
      },
      2 => { # Tuesday
        times: [[8, 30], [10, 3], [12, 4], [13, 38]],
        duration: 82,
        blocks: block_rotation[2..2].cycle
      },
      3 => { # Wednesday
        times: [[8, 30], [10, 3], [12, 4], [13, 38]],
        duration: 82,
        blocks: block_rotation[3..3].cycle
      },
      4 => { # Thursday
        times: [[8, 30], [10, 3], [12, 4], [13, 38]],
        duration: 82,
        blocks: block_rotation[4..4].cycle
      },
      5 => { # Friday
        times: [[8, 30], [9, 48], [11, 34], [12, 53]],
        duration: 67,
        blocks: block_rotation[1..4].cycle
      }
    }

    # blocks = [
    #   nil,
    #   %w[A B C D], # Monday
    #   %w[C D A B], # Tuesday
    #   %w[B A D C], # Wednesday
    #   %w[D C B A], # Thursday
    # ]
    # fridays = blocks[1..4].cycle

    # timeslots = [
    #   nil,
    #   [[8,30], [9,48], [11,34], [12,53]], # Monday
    #   [[8,30], [10,3], [12,4], [13,38]], # Tuesday
    #   [[8,30], [10,3], [12,4], [13,38]], # Wednesday
    #   [[8,30], [10,3], [12,4], [13,38]], # Thursday
    #   [[8,30], [9,48], [11,34], [12,53]], # Monday
    # ]
    # durations = [nil, 67, 82, 82, 82, 67]

    # TODO: Semesters fall vs spring
    # TODO: Block A rotates 8 classes over fall semester
    # TODO: Teacher names

    cal.each_instructional_day do |date|
      day = school[date.wday]
      blocks = day[:blocks].next
      times = day[:times]
      duration = day[:duration]

      # TODO: next unless ((10.days.ago)..(21.days.from_now)).cover?(date)

      blocks.zip(times).each do |b, t|
        klass = cal.class_for_block(b)
        dtstart = DateTime.new(date.year, date.month, date.day, t[0], t[1])
        dtend = DateTime.new(date.year, date.month, date.day, t[0], t[1]) + Rational(duration * 60, 86400)
        icalendar.event do |e|
          # Time
          e.dtstamp = Icalendar::Values::DateTime.new(dtstart)
          e.dtstart = Icalendar::Values::DateTime.new(dtstart)
          e.dtend = Icalendar::Values::DateTime.new(dtend)
          # Alarm
          e.alarm do |a|
            a.summary = "#{klass[:name]} is starting in 5 minutes, in #{klass[:room]}"
            a.trigger = "-PT5M"
          end
          # Content
          e.summary = "#{b}: #{klass[:name]}"
          e.description = "#{b}: #{klass[:name]}" # TODO: Add teacher?
          e.location = klass[:room]
          e.ip_class = "PUBLIC"
        end
      end
    end
  end
end

class Cal
  extend CalSeeder # Vaguely quacks ActiveRecord
  attr_reader :icalendar

  attr_reader :starts_on, :ends_on, :non_instructional_days

  def initialize(uuid)
    @icalendar = Icalendar::Calendar.new
  end

  def to_ical
    @icalendar.publish
    @icalendar.to_ical
  end

  def to_html
    @icalendar.publish
    @icalendar.to_ical
  end

  def set_term(starts_on:, ends_on:, non_instructional_days: [])
    @starts_on = starts_on
    @ends_on = ends_on
    @non_instructional_days = non_instructional_days
  end

  def set_classes(classes)
    @classes = classes
  end

  def class_for_block(block)
    @classes.detect { |klass| klass[:block] == block }
  end

  def each_instructional_day
    # Always run from starts_on to ends_on for consistent rotating
    # schedules, even if we only output a few weeks of classes.
    starts_on.upto(ends_on) do |date|
      next if non_instructional_days.include?(date)
      next if date.saturday? || date.sunday?

      yield date
    end
  end
end
