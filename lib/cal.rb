require "icalendar"

module CalSeeder
  def find(uuid)
    cal = new(uuid)
    if uuid == "018a805b-d352-76ec-9792-044d683090c2"
      seed_cal_data(cal)
    end
    cal
  end

  def seed_cal_data(cal)
    cal.seed_term(
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

    cal.seed_classes([
      # TODO: Add teacher names, days of term for shorter class blocks
      {block: "A", name: "Wood Work", room: "B103"},
      {block: "B", name: "Science 8", room: "C216"},
      {block: "C", name: "English 8", room: "PT02"},
      {block: "D", name: "Ph E", room: "Gym 4"}
    ])

    cal.seed_block_rotations([
      {name: "mon", blocks: %w[A B C D]},
      {name: "tue", blocks: %w[C D A B]},
      {name: "wed", blocks: %w[B A D C]},
      {name: "thu", blocks: %w[D C B A]}
    ])

    cal.seed_bell_schedule([
      { # Monday
        wday: 1,
        times: [[8, 30], [9, 48], [11, 34], [12, 53]],
        duration: 67,
        blocks: ["mon"].cycle
      },
      { # Tuesday
        wday: 2,
        times: [[8, 30], [10, 3], [12, 4], [13, 38]],
        duration: 82,
        blocks: ["tue"].cycle
      },
      { # Wednesday
        wday: 3,
        times: [[8, 30], [10, 3], [12, 4], [13, 38]],
        duration: 82,
        blocks: ["wed"].cycle
      },
      { # Thursday
        wday: 4,
        times: [[8, 30], [10, 3], [12, 4], [13, 38]],
        duration: 82,
        blocks: ["thu"].cycle
      },
      { # Friday
        wday: 5,
        times: [[8, 30], [9, 48], [11, 34], [12, 53]],
        duration: 67,
        blocks: ["mon", "tue", "wed", "thu"].cycle
      }
    ])

    ###### Above: Normalized, below: hardcoded logic

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
  end
end

class Cal
  extend CalSeeder # Vaguely quacks ActiveRecord

  # Term
  attr_reader :starts_on, :ends_on, :non_instructional_days
  # Associations
  attr_reader :classes, :block_rotations

  def initialize(uuid)
    @uuid = uuid
  end

  def to_ical
    icalendar ||= Icalendar::Calendar.new

    each_class_instance do |klass|
      icalendar.event do |e|
        # Time
        e.dtstamp = Icalendar::Values::DateTime.new(klass[:dtstart])
        e.dtstart = Icalendar::Values::DateTime.new(klass[:dtstart])
        e.dtend = Icalendar::Values::DateTime.new(klass[:dtend])
        # Alarm
        e.alarm do |a|
          a.summary = "#{klass[:name]} is starting in 5 minutes, in #{klass[:room]}"
          a.trigger = "-PT5M"
        end
        # Content
        e.summary = "#{klass[:block]}: #{klass[:name]}"
        e.description = "#{klass[:block]}: #{klass[:name]}" # TODO: Add teacher?
        e.location = klass[:room]
        e.ip_class = "PUBLIC"
      end
    end

    icalendar.publish
    icalendar.to_ical
  end

  def to_html
    # TODO: custom HTML payload instead
    to_ical
  end

  def seed_bell_schedule(bell_schedule)
    @bell_schedule = bell_schedule
  end

  def seed_block_rotations(block_rotations)
    @block_rotations = block_rotations
  end

  def seed_classes(classes)
    @classes = classes
  end

  def seed_term(starts_on:, ends_on:, non_instructional_days: [])
    @starts_on = starts_on
    @ends_on = ends_on
    @non_instructional_days = non_instructional_days
  end

  private

  def bell_schedule(wday)
    @bell_schedule.detect { |day| day[:wday] == wday }
  end

  def class_for_block_and_date(block, date)
    classes.detect { |klass|
      next unless klass[:days].nil? || klass[:days].cover?(date)
      klass[:block] == block
    }
  end

  def each_instructional_day
    # Always generate full schedule for consistent cycles,
    # even if caller only needs a subset of dates.
    starts_on.upto(ends_on) do |date|
      next if non_instructional_days.include?(date)
      next if date.saturday? || date.sunday?

      yield date
    end
  end

  def each_class_instance
    each_instructional_day do |date|
      day = bell_schedule(date.wday)
      block_rotation = day[:blocks].next
      blocks = block_rotations.detect { |br| br[:name] == block_rotation }[:blocks]
      times = day[:times]
      duration = day[:duration]

      # TODO: next unless ((10.days.ago)..(21.days.from_now)).cover?(date)

      blocks.zip(times).each do |block, t|
        klass = class_for_block_and_date(block, date)
        dtstart = DateTime.new(date.year, date.month, date.day, t[0], t[1])
        dtend = DateTime.new(date.year, date.month, date.day, t[0], t[1]) + Rational(duration * 60, 86400)

        yield(klass.merge(dtstart: dtstart, dtend: dtend, block: block))
      end
    end
  end
end
