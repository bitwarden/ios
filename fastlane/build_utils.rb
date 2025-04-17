#!/usr/bin/env ruby
require 'dotenv'

module BuildUtils
    def self.fetch_provisioning_profiles(provisioning_profiles, folder_path, account_name, container_name)
        puts "Account Name: #{account_name}"
        puts "Container Name: #{container_name}"
        puts "Folder Path: #{folder_path}"

        provisioning_profiles.each do |profile|
            # command = "echo \"Downloading #{profile} from #{container_name} in account #{account_name} to #{folder_path}\""
            command = "az storage blob download --account-name #{account_name} --container-name #{container_name} --name #{profile} --file #{folder_path}/#{profile}"

            #puts "Executing: #{command}"
            system(command)

            Check if command was successful
            if $?.success?
                puts "Successfully downloaded #{profile}"
            else
                puts "Failed to download #{profile}, exit code: #{$?.exitstatus}"
            end
        end
    end

    def self.fetch_file(source_filename, filepath, account_name, container_name)
        puts "Account Name: #{account_name}"
        puts "Container Name: #{container_name}"
        puts "File Path: #{filepath}"

        # command = "echo \"Downloading #{source_filename} from #{container_name} in account #{account_name} to #{filepath}\""
        command = "az storage blob download --account-name #{account_name} --container-name #{container_name} --name #{source_filename} --file #{filepath}"
        system(command)

        Check if command was successful
        if $?.success?
            puts "Successfully downloaded #{profile}"
        else
            puts "Failed to download #{profile}, exit code: #{$?.exitstatus}"
        end
    end
end