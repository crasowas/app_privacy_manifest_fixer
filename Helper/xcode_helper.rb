# Copyright (c) 2024, crasowas.
#
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

require 'xcodeproj'

RUN_SCRIPT_PHASE_NAME = 'Fix Privacy Manifest'

if ARGV.length < 2
  puts "Usage: ruby xcode_helper.rb <project_root_path> <script_content>"
  exit 1
end

project_root_path = ARGV[0]
run_script_content = ARGV[1]

# Find the first .xcodeproj file in the project root directory
project_path = Dir.glob(File.join(project_root_path, "*.xcodeproj")).first

# Validate the project path
unless project_path
  puts "❌ Error: No .xcodeproj file found in the specified directory."
  exit 1
end

# Open the Xcode project file
begin
  project = Xcodeproj::Project.open(project_path)
rescue StandardError => e
  puts "❌ Error: Unable to open the project file - #{e.message}"
  exit 1
end

# Get the first target in the project
target = project.targets.first

if target.nil?
  puts "❌ Error: No targets found in the project."
  exit 1
end

# Check for an existing Run Script phase with the specified name
existing_phase = target.shell_script_build_phases.find { |phase| phase.name == RUN_SCRIPT_PHASE_NAME }

# Remove the existing Run Script phase if found
if existing_phase
  puts "Removing existing Run Script..."
  target.build_phases.delete(existing_phase)
end

# Add the new Run Script phase at the end
puts "Adding Run Script..."
new_phase = target.new_shell_script_build_phase(RUN_SCRIPT_PHASE_NAME)
new_phase.shell_script = run_script_content

# Save the project file
begin
  project.save
  puts "✅ Run Script '#{RUN_SCRIPT_PHASE_NAME}' added successfully!"
rescue StandardError => e
  puts "❌ Error: Unable to save the project file - #{e.message}"
  exit 1
end
