#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 21 Mar 2019
# Description: Class representing the trophies of either the player or one
# brawler
#

class Trophies
    attr_accessor :rank, :trophies, :max_trophies

    def initialize()
        @rank = 0
        @trophies = 0
        @max_trophies = 0
    end

    # Used only for brawland website
    def update_all( match_result )
        @rank = match_result[ 0 ]
        @rank.strip! if @rank.is_a? String
        @trophies = match_result[ 1 ]
        @max_trophies = match_result[ 2 ]
    end

    def update_trophies( current, highest, object_class )
        @trophies = current
        @max_trophies = highest
        @rank = Trophies.find_rank( @max_trophies, object_class )
    end

    def printable()
        return "Rank: #{@rank} Trophies: #{@trophies} (#{@max_trophies}) [#{@trophies-@max_trophies}]"
    end

    def export_to_csv()
        return "#{@rank}\t#{@trophies}\t#{@max_trophies}"
    end

    def export_to_json()
        return { "rank": @rank, "trophies": @trophies, "max_trophies": @max_trophies }
    end

    def self.compare( a, b )
        result = Trophies.new()
        result.rank = "#{a.rank} vs #{b.rank}"
        result.trophies = a.trophies - b.trophies
        result.max_trophies = a.max_trophies - b.max_trophies
        return result
    end

    def self.find_rank( trophies, object_class )
        index = 0
        if object_class == "Player" then
            while index < PLAYER_RANKS.length and trophies >= PLAYER_RANKS[ index ][ 0 ] do
                index += 1
            end
            return PLAYER_RANKS[ index - 1 ][ 1 ]
        elsif object_class == "Brawler" then
            return 0 if trophies == 0 
            while index < BRAWLER_RANKS.length and trophies >= BRAWLER_RANKS[ index ] do
                index += 1
            end
            return index
        end
    end
end

