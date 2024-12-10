# Copyright (c) 2024, crasowas.
#
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

require 'xcodeproj'

RUN_SCRIPT_PHASE_NAME = 'Fix Privacy Manifest'

if ARGV.length < 1
  puts "Usage: ruby xcode_uninstall_helper.rb <project_path>"
  exit 1
end

project_path = ARGV[0]

# Find the first .xcodeproj file in the project directory
xcodeproj_path = Dir.glob(File.join(project_path, "*.xcodeproj")).first

# Validate the .xcodeproj file existence
unless xcodeproj_path
  puts "Error: No .xcodeproj file found in the specified directory."
  exit 1
end

# Open the Xcode project file
begin
  project = Xcodeproj::Project.open(xcodeproj_path)
rescue StandardError => e
  puts "Error: Unable to open the project file - #{e.message}"
  exit 1
end

# Process all targets in the project
project.targets.each do |target|
  # Check if the target is an application target
  if target.product_type == 'com.apple.product-type.application'
    puts "Processing target: #{target.name}..."

    # Check for an existing Run Script phase with the specified name
    existing_phase = target.shell_script_build_phases.find { |phase| phase.name == RUN_SCRIPT_PHASE_NAME }

    # Remove the existing Run Script phase if found
    if existing_phase
      puts "  - Removing existing Run Script."
      target.build_phases.delete(existing_phase)
    else
      puts "  - No existing Run Script found."
    end
  else
    puts "Skipping non-application target: #{target.name}."
  end
end

# Save the project file
begin
  project.save
  puts "Successfully removed the Run Script phase: '#{RUN_SCRIPT_PHASE_NAME}'."
rescue StandardError => e
  puts "Error: Unable to save the project file - #{e.message}"
  exit 1
end
