#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Wed 20 Mar 2019
# Description: Getting stats from brawlstats.com of one or more players and
# compare them with a nice UI
#

require "./Constants.rb"
require "./Player.rb"


# Functions
def clean_string( string )
    return string.strip.gsub( /\s+/, " " )
end

# ~~~~~~~~~~~~~ MAIN ~~~~~~~~~~~~~
update = ( ARGV[ 0 ] == "update" )

players = Players.new( IDS )
players.update_stats() if update
puts "#{players.printable_intro()}"
puts "#{players.printable_full()}"

# Comparing statistics between players
puts " === COMPARISON === "
player_compared_stats = players.compare_to( ID_MINE )
player_compared_stats.each do |player_comparison|
    puts " => #{player_comparison.printable()}"
end

# Exporting data to csv file
players.export_to_csv()
players.update_players_csv_stats() if update
players.create_graphs( ID_MINE )

