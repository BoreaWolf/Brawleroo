#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 21 Mar 2019 
# Description: Class representing the trophies of either the player or one
# brawler
#

PLAYER_RANKS = [ [ 0, "Unranked" ],
                 [ 500, "Wood I" ],
                 [ 650, "Wood II" ],
                 [ 800, "Wood III" ],
                 [ 1000, "Bronze I" ],
                 [ 1300, "Bronze II" ],
                 [ 1600, "Bronze III" ],
                 [ 2000, "Silver I" ],
                 [ 2300, "Silver II" ],
                 [ 2600, "Silver III" ],
                 [ 3000, "Gold I" ],
                 [ 3300, "Gold II" ],
                 [ 3600, "Gold III" ],
                 [ 4000, "Diamond I" ],
                 [ 4500, "Diamond II" ],
                 [ 5000, "Diamond III" ],
                 [ 5500, "Diamond IV" ],
                 [ 6000, "Crystal I" ],
                 [ 6500, "Crystal II" ],
                 [ 7000, "Crystal III" ],
                 [ 7500, "Crystal IV" ],
                 [ 8000, "Master I" ],
                 [ 8500, "Master II" ],
                 [ 9000, "Master III" ],
                 [ 9500, "Master IV" ],
                 [ 10000, "All-Star I" ],
                 [ 11000, "All-Star II" ],
                 [ 12000, "All-Star III" ],
                 [ 13000, "All-Star IV" ],
                 [ 14000, "All-Star V" ] ]

class Trophies
    attr_accessor :rank, :trophies, :max_trophies

    def initialize()
        @rank = 0
        @trophies = 0
        @max_trophies = 0
    end
    
    def update_all( match_result )
        @rank = match_result[ 0 ]
        @rank.strip! if @rank.is_a? String
        @trophies = match_result[ 1 ]
        @max_trophies = match_result[ 2 ]
    end

    def update_trophies( current, highest )
        @trophies = current
        @max_trophies = highest
        @rank = find_rank( @max_trophies )
    end

    def find_rank( trophies )
        index = 0
        while index < PLAYER_RANKS.length and trophies > PLAYER_RANKS[ index ][ 0 ] do
            index += 1
        end
        return PLAYER_RANKS[ index - 1 ][ 1 ]
    end

    def printable()
        return "Rank: #{@rank} Trophies: #{@trophies} (#{@max_trophies}) [#{@trophies-@max_trophies}]"
    end

    def self.compare( a, b )
        result = Trophies.new()
        result.rank = "#{a.rank} vs #{b.rank}"
        result.trophies = a.trophies - b.trophies
        result.max_trophies = a.max_trophies - b.max_trophies
        return result
    end
end

