#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Sat 22 Jun 2019 
# Description: Transforming all data collected up to today from csv to json
#

require "json"

require "./Constants.rb"
require "./Player.rb"

# Reading all csv files in the Stats folder
Dir[ "#{EXPORT_FILE_DIR}/*#{EXPORT_FILE_EXT}" ].each do |csv_file_name|
    print "Working on file '#{csv_file_name}'."
    player_id = File.basename( csv_file_name, EXPORT_FILE_EXT )
    # Each line is an update, which will be translated in one entry of the final
    # json
    # I will try to create a Player instance for each line and then jsonify it
    result = {}
    File.readlines( csv_file_name ).each do |line_data|
        player = Player.new( "" )
        match = line_data.scan( REGEX_FILE_LINE_STATS )[ 0 ]
        # Match components:
        #   0 = date
        #   1 = Player info
        #   2 = Brawlers info
        player_info = match[ 1 ].split( "\t" )
        player.name = player_info[ 0 ]
        player.id = player_info[ 1 ]
        player.image = "28000000"
        player.trophies.rank = player_info[ 2 ]
        player.trophies.trophies = player_info[ 3 ].to_i
        player.trophies.max_trophies = player_info[ 4 ].to_i
        player.victories.trio = player_info[ 5 ].to_i
        player.victories.duo = player_info[ 6 ].to_i
        player.victories.solo = player_info[ 7 ].to_i
        brawlers_info = match[ 2 ].scan( REGEX_FILE_LINE_CHAR_STATS )
        brawlers_info.each.with_index do |info,i|
            player.brawlers.get_brawler( CHARS[ i ][ 0 ] ).update( info.map{ |x| x.to_i } )
        end
        # Saving the current update under the date when the data was
        # gathered
        result[ match[ 0 ] ] = player.export_to_json()
    end

    # Saving everything on file with the new json format
    File.open( "#{EXPORT_FILE_DIR}/#{player_id}#{EXPORT_FILE_JSON_EXT}", "w" ) do |export_file|
        export_file.write( JSON.generate( result ) )
    end
    puts "...DONE o(^▽^)o"
end
