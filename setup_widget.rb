require 'xcodeproj'
require 'fileutils'

project_path = 'ios/Runner.xcodeproj'
unless File.exist?(project_path)
  puts "Error: ios/Runner.xcodeproj not found."
  exit 1
end

project = Xcodeproj::Project.open(project_path)

# 1. Configuration
widget_name = 'WidgetExtension'
app_bundle_id = 'dev.albazeli.unitask'
widget_bundle_id = "#{app_bundle_id}.WidgetExtension"
app_group_id = "group.#{app_bundle_id}"

# 2. Add files to a Group in Xcode
# This does NOT move files on disk, it just registers them in the project.
group = project.main_group.find_subpath(widget_name, true)
group.set_source_tree('<group>')

file_list = [
  "ios/#{widget_name}/#{widget_name}.swift",
  "ios/#{widget_name}/Info.plist",
  "ios/#{widget_name}/#{widget_name}.entitlements"
]

# Ensure files exist on disk before adding
file_list.each do |f|
  unless File.exist?(f)
    puts "Warning: Mandatory file #{f} not found on disk. Continuing anyway..."
  end
end

swift_file_ref = group.new_file("WidgetExtension.swift")
plist_file_ref = group.new_file("Info.plist")
entitlements_file_ref = group.new_file("#{widget_name}.entitlements")

# 3. Create the Target
# Check if it already exists to avoid duplicates
existing_target = project.targets.find { |t| t.name == widget_name }
if existing_target
  puts "Target #{widget_name} already exists. Removing for fresh setup..."
  existing_target.remove_from_project
end

widget_target = project.new_target(:app_extension, widget_name, :ios, '14.0')

# 4. Add Build Phases
widget_target.add_file_references([swift_file_ref])

# 5. Build Settings & Entitlements
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = widget_bundle_id
  config.build_settings['INFOPLIST_FILE'] = "#{widget_name}/Info.plist"
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = "#{widget_name}/#{widget_name}.entitlements"
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['SKIP_INSTALL'] = 'YES'
end

# 6. Link Widget to App
app_target = project.targets.find { |t| t.name == 'Runner' }
if app_target
  # Add dependency (so widget builds with app)
  app_target.add_dependency(widget_target)
  
  # Embed App Extension in the main bundle
  embed_phase = app_target.copy_files_build_phases.find { |p| p.name == 'Embed App Extensions' } || 
                app_target.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.symbol_dst_subfolder_spec = :app_extension
  
  build_file = embed_phase.add_file_reference(widget_target.product_reference, true)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  puts "Successfully linked Widget to Runner target."
else
  puts "Warning: Runner target not found. Could not link widget."
end

# 7. Save Project
project.save
puts "Successfully configured #{widget_name} Target and linked files."
