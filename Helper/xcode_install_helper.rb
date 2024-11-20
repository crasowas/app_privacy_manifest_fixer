# Copyright (c) 2024, crasowas.
#
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

require 'xcodeproj'

RUN_SCRIPT_PHASE_NAME = 'Fix Privacy Manifest'

if ARGV.length < 2
  puts "Usage: ruby xcode_install_helper.rb <project_path> <script_content> [install_builds_only (true|false)]"
  exit 1
end

project_path = ARGV[0]
run_script_content = ARGV[1]
install_builds_only = ARGV[2] == 'true'

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

# Get the first target in the project
target = project.targets.first

if target.nil?
  puts "Error: No targets found in the project."
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
# Disable showing environment variables in the build log
new_phase.show_env_vars_in_log = '0'
# Run only for deployment post-processing if install_builds_only is true
new_phase.run_only_for_deployment_postprocessing = install_builds_only ? '1' : '0'

# Save the project file
begin
  project.save
  puts "Successfully added the Run Script phase: '#{RUN_SCRIPT_PHASE_NAME}'."
rescue StandardError => e
  puts "Error: Unable to save the project file - #{e.message}"
  exit 1
end