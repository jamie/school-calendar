require "roda"
require "./cal"

class App < Roda
  plugin :type_routing, types: {ics: "text/calendar"}

  route do |r|
    r.root do
      "404"
    end

    r.on "calendar" do
      r.on String do |uuid|
        cal = Cal.new(uuid)
        r.get do
          r.ics do
            response["Content-Type"] = "text/calendar"
            cal.to_ical
          end
          "<pre>#{cal.to_html}</pre>"
        end
      end
    end
  end
end

run App.freeze.app
