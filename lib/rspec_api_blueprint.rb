require "rspec_api_blueprint/version"
require "rspec_api_blueprint/string_extensions"


RSpec.configure do |config|
  config.add_setting :api_docs_output, default: 'api_docs'
  config.add_setting :api_docs_controllers, default: 'app/controllers'
  config.add_setting :api_docs_models, default: 'app/models'
  config.add_setting :api_docs_whitelist, default: false
  config.alias_example_to :docs, docs: true

  api_docs_folder_path = nil
  touched_files = {}

  config.before(:suite) do
    if defined? Rails
      api_docs_folder_path = File.join(Rails.root, config.api_docs_output)
    else
      api_docs_folder_path = File.join(File.expand_path('.'), config.api_docs_output)
    end

    Dir.mkdir(api_docs_folder_path) unless Dir.exists?(api_docs_folder_path)
  end

  RESOURCE_GROUP = /Group\s(\w+)/
  ACTION_GROUP = /(GET|POST|PATCH|PUT|DELETE)\s(.+)$/

  config.after(:each) do
    next if example.metadata[:docs] == false
    next if config.api_docs_whitelist && !example.metadata[:docs]

    response ||= last_response || @response
    request ||= last_request || @request

    next unless response

    action_group, action_match = find_group(example.metadata[:example_group], ACTION_GROUP)
    action_comment = parse_action_comment(action_group, config.api_docs_controllers)

    next unless action_group

    resource_group, resource_match = find_group(action_group, RESOURCE_GROUP)
    resource_comment = parse_resource_comment(resource_group, config.api_docs_models)

    next unless resource_group

    resource_name = resource_match[1]
    file_name = resource_name.underscore

    file = File.join(api_docs_folder_path, "#{file_name}.md")
    
    new_file = false
    if !touched_files[file_name]
      File.delete(file) if File.exists?(file)
      new_file = true
      touched_files[file_name] = true
    end

    File.open(file, 'a+') do |f|
      # Resource
      if new_file
        f.puts "# Group #{resource_name}\n\n"

        f.puts resource_comment
      end

      # Action
      if new_file || !f.read.index(Regexp.new(Regexp.escape(action_match.to_s) + "$"))
        f.puts "## #{action_match}"

        f.puts action_comment
      end

      # Request
      request_body = request.body.read
      request_content_type = request.content_type
      authorization_header = request.env ? request.env['Authorization'] : request.headers['Authorization']

      if request_body.present? || authorization_header.present?
        # Parse JSON body form style requests that simple rspec tests produce
        if request_content_type == 'application/x-www-form-urlencoded'
          request_content_type = 'application/json'
          request_body = Rack::Utils.parse_nested_query(request_body).to_json
        end

        f.puts "+ Request #{example.metadata[:description_args].first} (#{request_content_type})\n\n"

        # Request Headers
        if authorization_header.present?
          f.puts "+ Headers\n\n"
          f.puts "Authorization: #{authorization_header}\n\n".indent(2)
        end

        # Request Body
        if request_body.present? && request_content_type.include?('application/json')
          f.puts "+ Body\n".indent(2) if authorization_header
          f.puts "#{JSON.pretty_generate(JSON.parse(request_body))}\n\n".indent(authorization_header ? 6 : 4)
        end
      end

      # Response
      f.puts "+ Response #{response.status} (#{response.content_type})\n\n"

      if response.body.present? && response.content_type.include?('application/json')
        f.puts "#{JSON.pretty_generate(JSON.parse(response.body))}\n\n".indent(4)
      end
    end unless response.status == 401 || response.status == 403 || response.status == 301
  end

  private

  # Go up in the example group (i.e. describe/context) hierarchy and try to match the text.
  # @return matched example group, matched regex
  def find_group(example_group, regex)
    group = nil

    begin
      match = example_group[:description_args].first.match(regex)
      example_group = example_group[:example_group] unless match
    end while !match && example_group

    return example_group, match
  end

  # Parse documentation from controller's comment
  def parse_action_comment(example_group, folder)
    return nil unless example_group

    resource = example_group[:file_path].match(/([a-zA-Z_-]+)_spec\.rb/)[1].singularize
    file_path = folder.is_a?(Proc) ? folder.call(resource) : File.join(folder, resource.pluralize + '_controller.rb')

    in_comment = false
    comment_lines = []

    File.open(file_path, 'r').each do |line|
      if in_comment
        if line =~ /\s*# ?(.*)$/
          comment_lines << $1
        else
          comment_lines << ""
          break
        end
      elsif line =~ Regexp.new("\s*#\s*" + Regexp.escape(example_group[:description_args].first) + "\s*$")
        in_comment = true
      end
    end

    puts "Cannot find docs for action #{example_group[:description_args].first}" if comment_lines.size == 0

    comment_lines
  end

  # Parse documentation from model's comment
  def parse_resource_comment(example_group, folder)
    return nil unless example_group

    resource = example_group[:file_path].match(/([a-zA-Z_-]+)_spec\.rb/)[1].singularize
    file_path = folder.is_a?(Proc) ? folder.call(resource) : File.join(folder, resource + '.rb')

    lines = File.read(file_path).lines.to_a
    row = 0

    in_comment = false
    comment_lines = []

    File.open(file_path, 'r').each do |line|
      if in_comment
        if line =~ /\s*# ?#* ?(.*)$/
          comment_lines << $1
        else
          comment_lines << ""
          break
        end
      elsif line =~ Regexp.new("\s*#\s*" + Regexp.escape(example_group[:description_args].first) + "\s*$")
        in_comment = true
      end
    end

    if comment_lines.size == 0
      while row < lines.size
        if lines[row].match(/^\s*class \w+/)  # find first class definition
          row -= 1
          break
        else
          row += 1
        end
      end

      if row == lines.size
        puts "Cannot find docs for resource #{resource.camelize}"
        return nil
      end

      comment_lines = [""]

      while lines[row] =~ /\s*# ?(.*)$/
        comment_lines.unshift($1)
        row -= 1
      end
    end

    comment_lines
  end
end
