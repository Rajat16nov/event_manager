require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  if !phone_number.nil?
    phone_number = phone_number.to_s.gsub(/[^0-9]/, '')
    if phone_number.length < 10 || (phone_number[0] != "1" && phone_number.length >= 11)
      phone_number = "0000000000"
    end
    if phone_number.length == 11 && phone_number[0] == "1"
      phone_number = phone_number[1..10]
    end
  end
  phone_number
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def time_targeting(reg_dates)
  hours = []
  reg_dates.each do |reg_date|
    hours.push(reg_date.hour)
  end
  puts "Time Targeting: "
  puts hours.tally
  puts "Highest is #{hours.tally.key(hours.tally.values.max)}"

end


def day_targeting(reg_dates)
  days = []
  reg_dates.each do |reg_date|
    day_index = reg_date.wday
    days.push(Date::DAYNAMES[day_index])
  end
  puts "Day Targeting: "
  puts days.tally
  puts "Highest is #{days.tally.key(days.tally.values.max)}"

end


puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
) 

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

reg_dates = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  reg_date = DateTime.strptime(row[:regdate], "%m/%d/%y %H:%M")
  reg_dates.push(reg_date)
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end

time_targeting(reg_dates)
day_targeting(reg_dates)
