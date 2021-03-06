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

    attr_accessor :name, :rarity, :power, :trophies

    # In
    def initialize( name = "", rarity = "" )
        @name = name
        @rarity = rarity
        @power = 0
        @trophies = Trophies.new()
    end

    def update( stats )
        @power = stats[ 0 ]
        @trophies.update_trophies( stats[ 1 ], stats[ 2 ], self.class.name )
    end

    def is_unlocked()
        return ( not ( @power == 0 or @power == "0 vs 0" ) )
    end

    def printable()
        return "#{@name} (#{@rarity}): Power: #{@power} #{@trophies.printable()}"
    end

    def export_to_csv()
        return "#{@power}\t#{@trophies.trophies}\t#{@trophies.max_trophies}"
    end

    def export_to_json()
        return { "power": @power, "trophies": @trophies.export_to_json() }
    end

    def self.compare( a, b )
        result = Brawler.new( a.name, a.rarity )
        result.power = "#{a.power} vs #{b.power}"
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
        ORDERED_CHARS.each do |brawler_name, _, _|
            result +=  " - " + @brawler_list[ brawler_name ].printable() + "\n"
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

    def export_to_json()
        result = {}
        ORDERED_CHARS.each do |name, _, id|
            result[ id ] = get_brawler( name ).export_to_json()
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
