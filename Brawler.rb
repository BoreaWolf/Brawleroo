#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 21 Mar 2019 
# Description: Classes for Brawlers, single and all together
#

def find_char_name_by_brawlstats_id( id_brawlstats )
    CHARS.each do |name, _, id|
        if id == ( id_brawlstats - BRAWLSTATS_ID_CONSTANT ) then
            return name
        end
    end
    puts "ERROR! Could not find character name! #{id_brawlstats} [Brawler::find_char_name_by_brawlstats_id]"
    abort
end

class Brawler

    attr_accessor :name, :rarity, :trophies

    def initialize( name = "", rarity = "" )
        @name = name
        @rarity = rarity
        @trophies = Trophies.new()
    end

    def update( stats )
        @trophies.update_all( stats )
    end

    def is_unlocked()
        return ( not ( @trophies.rank == 0 or @trophies.rank == "0 vs 0" ) )
    end

    def printable()
        return "#{@name} (#{@rarity}): #{@trophies.printable()}"
    end

    def export_to_csv()
        return "#{@trophies.export_to_csv()}"
    end

    def self.compare( a, b )
        result = Brawler.new( a.name, a.rarity )
        result.trophies = Trophies.compare( a.trophies, b.trophies )
        return result
    end
end

class Brawlers

    # TODO: Add sorting brawlers based on different attributes

    attr_accessor :brawler_list

    def initialize()
        @brawler_list = Hash.new()
        CHARS.each do |char|
            @brawler_list[ char[ 0 ] ] = Brawler.new( char[ 0 ], RARITY[ char[ 1 ] ] )
        end
    end

    def get_brawler( name )
        return @brawler_list[ name ]
    end

    def get_unlocked()
        result = 0
        @brawler_list.each do |k, v|
            if v.is_unlocked() then
                result += 1
            end
        end
        return result
    end

    def update_brawler( name, stats )
        if name.is_a? String then
            @brawler_list[ name ].update( stats )
        else
            @brawler_list[ find_char_name_by_brawlstats_id( name ) ].update( stats )
        end
    end

    def printable()
        result = "Brawler list (#{get_unlocked()}/#{CHARS.length}):\n"
        @brawler_list.each do |_, data|
            result +=  " - " + data.printable() + "\n"
        end
        return result
    end

    def export_to_csv()
        result = ""
        CHARS.each do |char_name, _, _|
            result += "#{get_brawler( char_name ).export_to_csv()}\t"
        end
        return result
    end

    def self.compare( a, b )
        result = Brawlers.new()
        result.brawler_list.each do |name, brawler|
            result.brawler_list[ name ] = Brawler.compare( a.get_brawler( name ), b.get_brawler( name ) )
        end
        return result
    end
end
