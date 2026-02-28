require 'xcodeproj'

project_path = 'Bitwarden.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target_name = 'BitwardenSafariWebExtension'
target = project.targets.find { |t| t.name == target_name }

if target.nil?
  puts "Target #{target_name} not found."
  exit 1
end

# Find the Resources group under BitwardenSafariWebExtension
ext_group = project.main_group.children.find { |c| c.name == 'BitwardenSafariWebExtension' || c.path == 'BitwardenSafariWebExtension' }
if ext_group
  group = ext_group.children.find { |c| c.name == 'Resources' || c.path == 'Resources' }
end

if group.nil?
  puts "Failed to find Resources group."
  exit 1
end

files_to_add = ['popup.html', 'popup.css', 'popup.js']

files_to_add.each do |file_name|
  # We assume the files are already in BitwardenSafariWebExtension/Resources/
  file_path = File.join('BitwardenSafariWebExtension', 'Resources', file_name)
  
  # Check if already in the group
  existing = group.files.find { |f| f.path == file_name }
  if existing
    puts "#{file_name} already in group."
    file_ref = existing
  else
    file_ref = group.new_file(file_name)
    puts "Added #{file_name} to group."
  end
  
  # Add to target's resource build phase
  if target.resources_build_phase.files_references.include?(file_ref)
    puts "#{file_name} already in resources build phase."
  else
    target.resources_build_phase.add_file_reference(file_ref, true)
    puts "Added #{file_name} to resources build phase."
  end
end

project.save
puts "Successfully updated project."
