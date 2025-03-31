#!/usr/bin/env ruby
require 'dotenv'
require 'optparse'

module BuildUtils
    def self.fetch_provisioning_profiles(provisioning_profiles, folder_path, account_name, container_name)
        puts "Account Name: #{account_name}"
        puts "Container Name: #{container_name}"
        puts "Folder Path: #{folder_path}"

        provisioning_profiles.each do |profile|
            # Create a shell command using the arguments
            command = "echo \"Downloading #{profile} from #{container_name} in account #{account_name} to #{folder_path}\""

            # Azure storage blob download command
            #command = "az storage blob download --account-name #{account_name} --container-name #{container_name} --name #{profile} --file #{folder_path}/#{profile}"

            # Execute the command
            #puts "Executing: #{command}"
            system(command)

            # Check if command was successful
            # if $?.success?
            #     puts "Successfully downloaded #{profile}"
            # else
            #     puts "Failed to download #{profile}, exit code: #{$?.exitstatus}"
            # end
        end
    end

    def self.fetch_file(source_filename, filepath, account_name, container_name)
        puts "Account Name: #{account_name}"
        puts "Container Name: #{container_name}"
        puts "File Path: #{filepath}"

        # Create a shell command using the arguments
        command = "echo \"Downloading #{source_filename} from #{container_name} in account #{account_name} to #{filepath}\""

        # Azure storage blob download command
        #command = "az storage blob download --account-name #{account_name} --container-name #{container_name} --name #{source_filename} --file #{filepath}"

        # Execute the command
        #puts "Executing: #{command}"
        system(command)

        # Check if command was successful
        # if $?.success?
        #     puts "Successfully downloaded #{profile}"
        # else
        #     puts "Failed to download #{profile}, exit code: #{$?.exitstatus}"
        # end
    end

    def self.update_bundle_id(bundle_id, filepath)
        puts "Updating bundle ID to #{bundle_id} in #{filepath}"
        # Read the contents of the file
        file_contents = File.read(filepath)

    end
end

if __FILE__ == $0
    # Parse command line options
    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: build_utils.rb [options]"

      opts.on("-e", "--env ENV_FILE", "Specify .env file path (required)") do |env_file|
        options[:env_file] = env_file
      end

      opts.on("-sp", "--secrets-path SECRETS_PATH", "Folder path to download profiles to") do |path|
        options[:secrets_path] = path
      end

      opts.on("-asc", "--fastlane-creds-filename FILENAME", "Fastlane credentials filename") do |filename|
        options[:fastlane_creds_filename] = filename
      end

      opts.on("-c", "--crashlytics-filepath FILE_PATH", "Path to the crashlytics Google-services.json file") do |filepath|
        options[:crashlytics_filepath] = filepath
      end

      opts.on("-cw", "--crashlytics-watch-filepath FILE_PATH", "Path to the crashlytics Google-services.json file for watchOS") do |filepath|
        options[:watch_crashlytics_filepath] = filepath
      end

      opts.on("-a", "--az-account ACCOUNT_NAME", "Azure Storage account name") do |account|
        options[:account_name] = account
      end

      opts.on("-pc", "--az-profiles-container CONTAINER_NAME", "Provisioning profiles Azure Storage container name") do |container|
        options[:profiles_container_name] = container
      end

      opts.on("-fc", "--az-files-container CONTAINER_NAME", "Files Azure Storage container name") do |container|
        options[:files_container_name] = container
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end
    parser.parse!

    mandatory = [:env_file, :secrets_path, :crashlytics_path, :watch_crashlytics_path, :account_name, :profiles_container_name, :files_container_name]
    missing = mandatory.select{ |param| options[param].nil? }
    unless missing.empty? then
      puts "Missing required arguments: #{missing.join(', ')}"
      puts parser
      exit 1
    end

    # Load environment variables from specified .env file
    Dotenv.load(options[:env_file])

    account_name = options[:account_name]
    profiles_container_name = options[:profiles_container_name]
    files_container_name = options[:files_container_name]
    secrets_path = options[:secrets_path]
    fastlane_creds_filename = options[:fastlane_creds_filename]
    fastlane_creds_filepath = secrets_path + fastlane_creds_filename
    local_crashlytics_filepath = options[:crashlytics_filepath]
    local_watch_crashlytics_filepath = options[:watch_crashlytics_filepath]
    provisioning_profiles = ENV['PROVISIONING_PROFILES'].delete(" \t\r\n").split(',')
    azure_crashlytics_filename = ENV['AZURE_CRASHLYTICS_FILE_NAME']

    BuildUtils.fetch_provisioning_profiles(provisioning_profiles, secrets_path, account_name, profiles_container_name)
    BuildUtils.fetch_file(azure_crashlytics_filename, local_crashlytics_filepath, account_name, files_container_name)
    BuildUtils.fetch_file(azure_crashlytics_filename, local_watch_crashlytics_filepath, account_name, files_container_name)
    BuildUtils.fetch_file(fastlane_creds_filename, fastlane_creds_filepath, account_name, files_container_name)
end