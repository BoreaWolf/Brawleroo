#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Sat 22 Jun 2019 
# Description: Transforming all data collected up to today from csv to json
#

require "date"
require "json"

require "./Constants.rb"
require "./Player.rb"

# Reading all json files from the Stats folder
Dir[ "#{EXPORT_FILE_DIR}/*#{EXPORT_FILE_JSON_EXT}" ].each do |json_file_name|
    print "Working on file '#{json_file_name}'."
    # Each line is an update, which will be translated in one entry of the final
    # json
    # I will try to create a Player instance for each line and then jsonify it
    result = JSON.parse( File.read( json_file_name ) )
    if result then
        begin
            # Using only Date and not DateTime because I only need to check for
            # the current day, I do not care about the time
            if Date.parse( result.keys.last, EXPORT_FILE_TIME_FORMAT ) == DateTime.now.to_date then
                result.delete( result.keys.last )
                File.open( json_file_name, "w" ).write( JSON.generate( result ) )
            end
        rescue ArgumentError
            # Key is not a date
        end
    end
    puts "...DONE o(^▽^)o"
end
