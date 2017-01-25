#!/usr/bin/env ruby

require 'csv'
require 'fileutils'
require 'set'

def extract_phone(str)
  match = /.*(\d{3}\s\d{3}[\.\-\s]\d{4}).*/.match(str)
  phone = match && match[1]
  if phone
    phone.gsub(/[\s\.]/, '-')
  end
end


FileUtils.rm_rf('output')
FileUtils.mkdir_p('output')

# school.csv
CSV.open('output/school.csv', 'wb', write_headers: true, headers: %w[school_id school_name school_zip]) do |out|
  out << [
    1,
    'Inman Park Cooperative Preschool',
    30307
  ]
end

# students.csv
headers = %w[school_id student_id first_name last_name grade_level]
CSV.open('output/students.csv', 'wb', write_headers: true, headers: headers) do |out|
  CSV.foreach('students.csv', headers: true) do |row|
    out << [
      1,
      row['Child ID'],
      row['First Name'],
      row['Last Name'],
      'PK'
    ]
  end
end

# parents.csv
headers = %w[school_id student_id first_name last_name email mobile address language]
CSV.open('output/parents.csv', 'wb', write_headers: true, headers: headers) do |out|
  CSV.foreach('parents.csv', headers: true) do |row|
    out << [
      1,
      row['Child ID'],
      row['First Name'],
      row['Last Name'],
      row['Email'],
      extract_phone(row['Phone 1']),
      row.values_at('Add 1, Line 1', 'Add 1, Line 2', 'Add 1, City', 'Add 1, Region', 'Add 1, Postal Code').compact.join(', '),
      'en'
    ]
  end
end

# staff.csv
allowed = %w[Office T1 T2-a T2-b P1 P2 P3 P4]
headers = %w[school_id staff_id title first_name last_name email mobile]
CSV.open('output/staff.csv', 'wb', write_headers: true, headers: headers) do |out|
  CSV.foreach('staff.csv', headers: true) do |row|
    department = row['Primary Work Area']
    if allowed.include?(department)
      out << [
        1,
        row['Employee ID'],
        department,
        row['First Name'],
        row['Last Name'],
        row['Email'],
        extract_phone(row['Phone 1'])
      ]
    end
  end
end

# rosters.csv
class_ids = []
headers = %w[school_id section_id student_id]
CSV.open('output/rosters.csv', 'wb', write_headers: true, headers: headers) do |out|
  CSV.foreach('rosters.csv', headers: true) do |row|
    if row['First Name'].include?('PH')
      puts "Skipping roster entry for #{row['First Name']} #{row['Last Name']}"
      next
    end

    class_id = row['Classroom ID']
    unless class_ids.include?(class_id)
      class_ids << class_id
      puts "[#{class_id}] Which teacher has #{row['First Name']} #{row['Last Name']} in their class?"
    end

    out << [
      1,
      row['Classroom ID'],
      row['Child ID']
    ]
  end
end

# sections.csv
headers = %w[school_id section_id staff_id course_name]
CSV.open('output/sections.csv', 'wb', write_headers: true, headers: headers) do |out|
  class_ids.each do |section_id|
    out << [
      1,
      section_id,
      0,
      ''
    ]
  end
end
