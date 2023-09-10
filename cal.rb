require 'icalendar'

non_instructional_days = [
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
  Date.new(2024, 6, 28),
]

start_date = Date.new(2023, 9, 4)
end_date = Date.new(2023, 12, 31) # Just this year
# end_date = Date.new(2024, 6, 28)

block_rotation = [
  nil,
  %w[A B C D], # Monday
  %w[C D A B], # Tuesday
  %w[B A D C], # Wednesday
  %w[D C B A], # Thursday
]
school = {
  1 => { # Monday
    times: [[8,30], [9,48], [11,34], [12,53]],
    duration: 67,
    blocks: block_rotation[1..1].cycle
  },
  2 => { # Tuesday
    times: [[8,30], [10,3], [12,4], [13,38]],
    duration: 82,
    blocks: block_rotation[2..2].cycle
  },
  3 => { # Wednesday
    times: [[8,30], [10,3], [12,4], [13,38]],
    duration: 82,
    blocks: block_rotation[3..3].cycle
  },
  4 => { # Thursday
    times: [[8,30], [10,3], [12,4], [13,38]],
    duration: 82,
    blocks: block_rotation[4..4].cycle
  },
  5 => { # Friday
    times: [[8,30], [9,48], [11,34], [12,53]],
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

classes = {
  "A" => {name: "Wood Work", room: "B103"},
  "B" => {name: "Science 8", room: "C216"},
  "C" => {name: "English 8", room: "PT02"},
  "D" => {name: "Ph E", room: "Gym 4"},
}

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

# TODO: Semesters fall vs spring
# TODO: Block A rotates 8 classes over fall semester
# TODO: Teacher names

# Create a calendar with an event (standard method)
cal = Icalendar::Calendar.new

# Always run start_date to end_date for consistent Friday
# schedule, even if we only output a few weeks of classes.
start_date.upto(end_date) do |date|
  next if non_instructional_days.include?(date)
  next if date.saturday? || date.sunday?

  date = school[date.wday]
  blocks = date[:blocks].next
  times = date[:times]
  duration = date[:duration]

  # TODO: next unless ((10.days.ago)..(21.days.from_now)).cover?(date)

  blocks.zip(times).each do |b, t|
    klass = classes[b]
    dtstart = DateTime.new(date.year, date.month, date.day, t[0], t[1])
    dtend = DateTime.new(date.year, date.month, date.day, t[0], t[1]) + Rational(duration * 60, 86400)
    cal.event do |e|
      # Time
      e.dtstart     = Icalendar::Values::DateTime.new(dtstart)
      e.dtend       = Icalendar::Values::DateTime.new(dtend)
      # Alarm
      e.alarm do |a|
        a.summary = "#{klass[:name]} is starting in 5 minutes, in #{klass[:room]}"
        a.trigger = "-PT5M"
      end
      # Content
      e.summary     = "#{b}: #{klass[:name]}"
      e.description = "#{b}: #{klass[:name]}" # TODO: Add teacher?
      e.location    = klass[:room]
      e.ip_class    = "PUBLIC"
    end
  end
end

cal.publish
puts cal.to_ical
