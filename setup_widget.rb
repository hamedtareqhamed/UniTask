require 'xcodeproj'

# مسار المشروع
project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 1. تعريف اسم الويدجت والـ Bundle ID
widget_name = 'WidgetExtension'
target_bundle_id = 'dev.albazeli.unitask.WidgetExtension'

# 2. إضافة الـ Target (كأنك ضغطت New Target في Xcode)
widget_target = project.new_target(:app_extension, widget_name, :ios, '14.0')
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = target_bundle_id
  config.build_settings['INFOPLIST_FILE'] = "ios/#{widget_name}/Info.plist"
  config.build_settings['SWIFT_VERSION'] = '5.0'
end

# 3. حفظ التغييرات
project.save
puts "Successfully added #{widget_name} to Xcode project."
