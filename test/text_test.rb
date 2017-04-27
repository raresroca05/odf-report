require '../lib/odf-report'
require 'faker'


class Item
  attr_accessor :name, :inner_text

  def initialize(_name, _text)
    @name =_name
    @inner_text =_text
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

  @items << Item.new(Faker::Name.name, text)

end


item = @items.pop

report = ODFReport::Report.new("templates/test_text.odt") do |r|

  r.add_field("TAG_01", Faker::Company.name)
  r.add_field("TAG_02", Faker::Company.catch_phrase)

  r.add_calendar

end

report.generate("result/test_text.odt")
