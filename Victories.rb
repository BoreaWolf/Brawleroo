#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 21 Mar 2019 
# Description: Class representing the victories of the player
#

class Victories
    attr_accessor :trio, :duo, :solo

    def initialize()
        @trio = 0
        @duo = 0
        @solo = 0
    end

    def update_all( match_result )
        @trio = match_result[ 0 ]
        @solo = match_result[ 1 ]
        @duo = match_result[ 2 ]
    end

    def printable()
        return "Victories: #{@trio} 3v3, #{duo} 2v2, #{solo} 1v1"
    end

    def export_to_csv()
        return "#{@trio}\t#{@duo}\t#{@solo}"
    end

    def self.compare( a, b )
        result = Victories.new()
        result.trio = a.trio - b.trio
        result.duo = a.duo - b.duo
        result.solo = a.solo - b.solo
        return result
    end
end

