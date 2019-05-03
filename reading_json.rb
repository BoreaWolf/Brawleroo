#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 02 May 2019
# Description: Trying to find where the badges come from
#

require "json"

word_to_look_for = ARGV[ 0 ]

Dir[ "./CssImages/*.json" ].each do |json_file|
    json_data = JSON.parse( File.open( json_file ).read() )
    #   keys = [ "TID", "id", "scid", "en" ]
    json_data.each_with_index do |value, index|
        value.keys().each do |key|
            if ( value[ key ].class.name == "String" and value[ key ].include?( word_to_look_for.upcase ) ) or
               ( value[ key ].class.name == "String" and value[ key ].include?( word_to_look_for.downcase ) ) then
                puts "#{json_file}@#{index}: #{key} => #{value}"
            end
        end
    end
end

