#!/usr/bin/env ruby

require 'csv'
require 'fileutils'
require 'set'
require 'pathname'

def extract_phone(str)
  match = /.*(\d{3}\s\d{3}[\.\-\s]\d{4}).*/.match(str)
  phone = match && match[1]
  if phone
    phone.gsub(/[\s\.]/, '-')
  end
end

SCHOOL_ID = 1 # We only have one school entry in ParentSquare
GRADE = 'PK'  # Everyone gets assigned into ParentSquare's "pre-k" grade

INPUT_DIR = Pathname.new(ARGV[0] || '.')

FileUtils.rm_rf('output')
FileUtils.mkdir_p('output')

# school.csv
CSV.open('output/school.csv', 'wb', write_headers: true, headers: %w[school_id school_name school_zip]) do |out|
  out << [
    SCHOOL_ID,
    'Inman Park Cooperative Preschool',
    30307
  ]
end

# students.csv
headers = %w[school_id student_id first_name last_name grade_level]
CSV.open('output/students.csv', 'wb', write_headers: true, headers: headers) do |out|
  CSV.foreach(INPUT_DIR.join('students.csv'), encoding: 'ISO-8859-1', headers: true) do |row|
    out << [
      SCHOOL_ID,
      row['Child ID'],
      row['First Name'],
      row['Last Name'],
      GRADE
    ]
  end
end

# parents.csv
headers = %w[school_id student_id first_name last_name email mobile address language]
CSV.open('output/parents.csv', 'wb', write_headers: true, headers: headers) do |out|
  CSV.foreach(INPUT_DIR.join('parents.csv'), encoding: 'ISO-8859-1', headers: true) do |row|
    out << [
      SCHOOL_ID,
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

# rosters.csv
SchoolSection = Struct.new(:id, :name, :staff_id)
sections = {} # aka classrooms
headers = %w[school_id section_id student_id]
CSV.open('output/rosters.csv', 'wb', write_headers: true, headers: headers) do |out|
  CSV.foreach(INPUT_DIR.join('rosters.csv'), encoding: 'ISO-8859-1', headers: true) do |row|
    if row['First Name'].include?('PH')
      puts "Skipping roster entry for #{row['First Name']} #{row['Last Name']}"
      next
    end

    # Start collecting class information to connect teachers to classrooms for
    # the `sections.csv` report output
    #
    class_id = row['Classroom ID']
    unless sections.has_key?(class_id)
      sections[class_id] = SchoolSection.new(class_id, row['Primary Classroom'], nil)
    end

    out << [
      SCHOOL_ID,
      row['Classroom ID'],
      row['Child ID']
    ]
  end
end

# staff.csv
allowed = %w[Office T1 T2-a T2-b P1 P2 P3 P4]
headers = %w[school_id staff_id title first_name last_name email mobile]
CSV.open('output/staff.csv', 'wb', write_headers: true, headers: headers) do |out|
  CSV.foreach(INPUT_DIR.join('staff.csv'), encoding: 'ISO-8859-1', headers: true) do |row|
    staff_id = row['Employee ID']
    department = row['Primary Work Area']

    if allowed.include?(department)
      section = sections.find { |(_, s)| s.name == department }
      if section
        section[1].staff_id = staff_id
      end

      out << [
        SCHOOL_ID,
        staff_id,
        department,
        row['First Name'],
        row['Last Name'],
        row['Email'],
        extract_phone(row['Phone 1'])
      ]
    end
  end
end

# sections.csv
headers = %w[school_id section_id staff_id course_name]
CSV.open('output/sections.csv', 'wb', write_headers: true, headers: headers) do |out|
  sections.each do |(_, section)|
    if !section.staff_id
      puts "Missing staff information for Classroom #{section.id}: '#{section.name}'"
    end

    out << [
      SCHOOL_ID,
      section.id,
      section.staff_id || 0,
      section.name
    ]
  end
end

# email PS to see if they can re-run on the import when the files change, not nightly
# figure out process for getting reports from ProCare into PS (ask Kirk, Ben?)
# email to communications asking for help
