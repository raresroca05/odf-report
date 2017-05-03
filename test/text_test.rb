require '../lib/odf-report'
require 'faker'


class Item
  attr_accessor :event_name, :event_location

  def initialize(_name, _text)
    @event_name =_name
    @event_location =_text
  end
end


@items = []
3.times do

  text = <<-HTML
        <p>#{Faker::Lorem.sentence} <em>#{Faker::Lorem.sentence}</em> #{Faker::Lorem.sentence}</p>
        <p>#{Faker::Lorem.sentence} <strong>#{Faker::Lorem.paragraph(3)}</strong> #{Faker::Lorem.sentence}</p>
        <p>#{Faker::Lorem.paragraph}</p>
        <blockquote>
          <p>#{Faker::Lorem.paragraph}</p>
          <p>#{Faker::Lorem.paragraph}</p>
        </blockquote>
        <p style="margin: 150px">#{Faker::Lorem.paragraph}</p>
        <p>#{Faker::Lorem.paragraph}</p>
  HTML

  @items << Item.new(Faker::Name.name, "text")

end


item = @items.pop
collection = { Date.new(2017, 6, 6).to_s.to_sym => [{:event_name => 'Team1', :event_location => 'Gent'},{:event_name => 'Team1', :event_location => 'Brussels'}],
  Date.new(2017, 6, 14).to_s.to_sym => [{:event_name => 'Team2', :event_location => 'Oostende'}]}

report = ODFReport::Report.new("templates/test_text.odt") do |r|

  puts "Collection is a #{collection.is_a? (Hash)}"

  r.add_field("TAG_01", Faker::Company.name)
  r.add_field("TAG_02", Faker::Company.catch_phrase)

  r.add_calendar(collection, period: 'next-month')

end

report.generate("result/test_text.odt")
