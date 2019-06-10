#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 21 Mar 2019 
# Description: Class representing the experience cumulated by the player
#

class Experience
    attr_accessor :level, :total, :current, :to_next_level

    def initialize()
        @level = 0
        @total = 0
        @current = 0
        @to_next_level = 0
    end

    def update_all( match_result )
        @level = match_result[ 0 ]
        @total = match_result[ 1 ]
        @current = match_result[ 2 ]
        @to_next_level = match_result[ 3 ]
    end

    def update_total( total )
        @total = total
        compute_level()
    end

    def compute_level()
        @level = 1
        accumulated_exp = 0
        while ( accumulated_exp + experience_to_next_level() ) <= @total do
            accumulated_exp += experience_to_next_level()
            @level += 1
        end
        @current = @total - accumulated_exp
        @to_next_level = experience_to_next_level()
    end

    def experience_to_next_level()
        return 40 + ( ( @level - 1 ) * 10 )
    end

    def printable()
        return "Level: #{@level}\tExperience: #{@current}/#{@to_next_level} (#{@total})"
    end

    def self.compare( a, b )
        result = Experience.new()
        result.level = a.level - b.level
        result.total = a.total - b.total
        result.current = 0
        result.to_next_level = 0
        return result
    end
end

