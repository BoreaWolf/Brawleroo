#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 02 May 2019
# Description: Trying to find where the badges come from
#

require "base64"

REGEX_IMAGE = /url\(([^;]*);([^;]*),([^\)]*)/
REGEX_SVG = /url\(([^;]*);([^;]*);([^,]*),([^\)]*)/
REGEX_PNG_JS = /data:image\/png;base64,(?<code>[^\'\"]*)/
REGEX_IMAGES_JS = /data:image\/(?<ext>[^;]*);base64,(?<code>[^\'\"]*)/
image_matches = Array.new

file_types = [ ".js", ".css" ]
file_types.each do |file_type|
    Dir[ "./CssImages/*#{file_type}" ].each do |file|
        print "Studying '#{file}'."
        data = File.open( file ).readlines()
        data.each do |line|
            regex_used = REGEX_IMAGES_JS
            if not ( match = line.scan( regex_used ) ) == nil then
                match.each do |m|
                    #   if image_matches.size == 74 then
                    #       puts "#{m[ 0 ]}"
                    #       puts "#{line}"
                    #   end
                    File.open( "./CssImages/#{image_matches.size}.#{m[ 0 ].split( "+" )[ 0 ]}", "w" ) do |image_file|
                        image_file.puts Base64.decode64( m[ 1 ] )
                    end
                    image_matches.append( m )
                    print "."
                end
            end
        end
        print "\n"
    end
end
puts "Images found: #{image_matches.size}"

