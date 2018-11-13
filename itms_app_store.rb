require 'CSV'
require_relative 'itms_utils.rb'

class ITMSAppStore

  def self.description_string(locale_name)
    filename = "#{@@locales_directory}/#{locale_name}/app_store_description.txt"
    contents = File.open(filename, 'rb').read
    contents.force_encoding('UTF-8')
    contents
  end

  def self.whats_new_string(locale_name)
    filename = "#{@@locales_directory}/#{locale_name}/app_store_whats_new.txt"
    if !File.file?(filename)
      return nil
    end
    contents = File.open(filename, 'rb').read
    contents.force_encoding('UTF-8')
    contents
  end
  def self.keywords(raw_input)
    keywords_xml = ''
    keywords = raw_input.split(',')
    keywords.each do |keyword|
      keywords_xml += "<keyword><![CDATA[#{keyword.strip}]]></keyword>"
    end
    keywords_xml
  end

  def self.software_screenshots(locale_name)
    screenshots_xml = ''

    display_targets = ['iOS-3.5-in', 'iOS-4-in', 'iOS-4.7-in', 'iOS-5.5-in', 'iOS-iPad', 'iOS-iPad-Pro', 'iOS-iPad-Pro-2018', 'iOS-5.8-in', 'iOS-6.5-in']
    
    display_targets.each_with_index do |display_target, display_target_index|
      
      if @@base_image_names[display_target_index].empty?
        next
      end
      
      @@screenshot_count.times do |i|
        image_name = "#{@@base_image_names[display_target_index]}_#{i.to_s.rjust(2, '0')}.png"
        localized_image_name = "#{locale_name}_#{image_name}"
        localized_directory = "#{@@locales_directory}/#{locale_name}"

        image_data_string = ITMSUtils.image_data_string(localized_directory, localized_image_name)

        @@images_used << "#{localized_directory}/#{localized_image_name}"

        screenshots_xml += "<software_screenshot display_target=\"#{display_target}\" position=\"#{i + 1}\">"
        screenshots_xml += image_data_string
        screenshots_xml += "</software_screenshot>"
      end
    end

    screenshots_xml
  end

  def self.app_previews(locale_name)
    app_preview_xml = ''

    display_targets = ['iOS-3.5-in', 'iOS-4-in', 'iOS-4.7-in', 'iOS-5.5-in', 'iOS-iPad', 'iOS-iPad-Pro', 'iOS-iPad-Pro-2018', 'iOS-5.8-in', 'iOS-6.5-in']

    display_targets.each_with_index do |display_target, display_target_index|

      if @@base_image_names[display_target_index].empty?
        next
      end

      @@preview_count.times do |i|
        preview_name = "#{@@base_image_names[display_target_index]}_#{i.to_s.rjust(2, '0')}.mp4"
        localized_preview_name = "#{locale_name}_#{preview_name}"
        localized_directory = "#{@@locales_directory}/#{locale_name}"

        preview_data_string = ITMSUtils.preview_data_string(localized_directory, localized_preview_name)

        @@previews_used << "#{localized_directory}/#{localized_preview_name}"

        app_preview_xml += "<app_preview display_target=\"#{display_target}\" position=\"#{i + 1}\">"
        app_preview_xml += preview_data_string
        app_preview_xml += "</app_preview>"
      end
    end

    app_preview_xml
  end

  def self.locale_string(row_data)
    locale_name = row_data[0]
    output = "<locale name=\"#{locale_name}\">"
    output += "<title><![CDATA[#{row_data[1]}]]></title>"
    output += "<description><![CDATA[#{description_string(locale_name)}]]></description>"

    whats_new = whats_new_string(locale_name)
    if whats_new != nil
      output += "<version_whats_new><![CDATA[#{whats_new_string(locale_name)}]]></version_whats_new>"
    end

    output += "<keywords>#{keywords(row_data[2])}</keywords>"
    output += "<software_url>#{row_data[3]}</software_url>"
    output += "<privacy_url>#{row_data[4]}</privacy_url>"
    output += "<support_url>#{row_data[5]}</support_url>"

    if @@upload_screenshots
      output += "<software_screenshots>#{software_screenshots(locale_name)}</software_screenshots>"
    end
    if @@upload_previews
      output += "<app_previews>#{app_previews(locale_name)}</app_previews>"
    end
    output += "</locale>"
  end

  def self.app_store_xml(version, input_locale_filename, locales_directory, base_image_names, upload_screenshots, screenshot_count, upload_previews, preview_count)
    @@locales_directory = locales_directory
    @@base_image_names = base_image_names
    @@images_used = Set.new
    @@previews_used = Set.new
    
    @@upload_screenshots = upload_screenshots
    @@screenshot_count = screenshot_count
    @@upload_previews = upload_previews
    @@preview_count = preview_count

    input_locales = CSV.read(input_locale_filename, { :col_sep => "\t" ,:quote_char=>'"'})
    input_locales.delete_at(0)
    puts "[ITMS] Found #{input_locales.count} app store languages"

    output = "<version string=\"#{version}\"><locales>"
    input_locales.each do |row_data|
      output += locale_string(row_data)
    end
    output += "</locales></version>"

    return output, @@images_used, @@previews_used
  end

end