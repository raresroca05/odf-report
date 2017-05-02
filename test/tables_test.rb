require '../lib/odf-report'
require 'ostruct'
require 'faker'
require 'launchy'


@col1 = []
(1..40).each do |i|
  @col1 << {:event_name => "name #{i}", :idx => i, :address => "this is address #{i}"}
end


@col2 = []
@col2 << OpenStruct.new({:name => "josh harnet", :idx => "02", :address => "testing <&> ", :phone => 99025668, :zip => "90420-002"})
@col2 << OpenStruct.new({:name => "sandro duarte", :idx => "45", :address => "address with &", :phone => 88774451, :zip => "90490-002"})
@col2 << OpenStruct.new({:name => "ellen bicca", :idx => "77", :address => "<address with escaped html>", :phone => 77025668, :zip => "94420-002"})
@col2 << OpenStruct.new({:name => "luiz garcia", 'idx' => "88", :address => "address with\nlinebreak", :phone => 27025668, :zip => "94520-025"})

@col3, @col4, @col5 = [], [], []




report = ODFReport::Report.new("templates/test_text.odt") do |r|

  r.add_calendar(@col1, period: 'next-month') do |t|
    t.add_field(:event_name) { |item| item }
    t.add_field(:event_location, :name)
  end

end

report.generate("result/test_tables.odt")
