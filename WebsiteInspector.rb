#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 21 Mar 2019 
# Description: Functions to read data from different websites
#

require "json"
require "net/http"
require "uri"

class WebsiteInspector

    def read_stats_brawland( id, player )
        # Looking for data from either the website or locally if we already have
        # them
        # TODO: Use this to create a sort of history of the player
        file_name = "#{DIR_WEBPAGES}/#{id}.html"
        if not File.exists?( file_name ) then
            # Reading the page from the website
            link = "#{PLAYER_LINK}#{id}"
            puts "Saving locally information about player #{id}..."
            save_file = File.open( "#{DIR_WEBPAGES}/#{id}.html", "w" )
            save_file.write( open( link, &:read ) )
            save_file.close
        end
        
        puts " === Reading info of '#{id}' === "
        
        # Reading file of given id
        content = File.open( "#{DIR_WEBPAGES}/#{id}.html" ) { |f| Nokogiri::HTML(f) }
        
        # Reading data of the player
        player_badge = content.css( "h2.float-left" )
        player.image = player_badge.css( "img" ).first[ "src" ]
        player.name = clean_string( player_badge.text )
        player.name.slice!( player.name.index( "Player" )..-1 )
        player.name = player.name.strip
        
        trophies = nil
        experience = nil
        victories = nil
        # Data are in these divs with the card-body class
        content.css( "div.card-body" ).each do |div|
            trophies = clean_string( div.text ).match( REGEX_TROPHIES ) unless trophies != nil
            experience = clean_string( div.text ).match( REGEX_EXPERIENCE ) unless experience != nil
            victories = clean_string( div.text ).match( REGEX_VICTORIES ) unless victories != nil
        end
        
        player.trophies.update_all( trophies.captures )
        player.experience.update_all( experience.captures )
        player.victories.update_all( victories.captures )
        
        # Reading info about brawlers
        content.css( "div.brawlers-item" ).each do |brawler|
            stats = clean_string( brawler.text ).match( REGEX_BRAWLER ).captures
            player.brawlers.update_brawler( stats[ 0 ], stats[ 1..-1 ] )
        end
    end
    
    def read_stats_brawlstats( id, player, online )
        # For this website I need to send two requests: OPTIONS and GET
        #   if not File.exists?( "#{DIR_WEBPAGES}/#{id}.brawlstats" ) then
        if online or not File.exists?( "#{DIR_WEBPAGES}/#{id}.brawlstats" ) then
            puts "Saving locally information about player #{id}..."

            #   puts "WebsiteInspector::read_stats_brawlstats '#{id}' '#{player}'"
            uri = URI( "https://api.brawlstats.com/v6/players/profiles/#{id}" )
            # TODO: Find a way to get the Authorization value from the cookies
            # Request headers
            initheader_options =
                {
                    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                    "Accept-Encoding" => "gzip, deflate, br",
                    "Accept-Language" => "en-GB,en;q=0.5",
                    "Access-Control-Request-Headers" => "authorization",
                    "Access-Control-Request-Method" => "GET",
                    "Cache-Control" => "max-age=0",
                    "Connection" => "keep-alive"
                    #   "Host" => "api.brawlstars.com",
                    #   "Origin" => "https://brawlstats.com",
                    #   "Referer" => "https://brawlstats.com/profile/#{id}",
                    #   "TE" => "Trailers"
                }
            initheader_get =
                {
                    "Accept" => "application/json",
                    "Accept-Encoding" => "deflate",
                    "Accept-Language" => "en-GB,en;q=0.5",
                    "Authorization" => "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpcEFkZHJlc3MiOiIxNDMuMjM5LjkuNyIsInV1aWQiOiI0ZDZjMzlkMS0yMWYwLTQyMWQtYmY5NS1iNTdiZTdkYzhhNmEiLCJyb2xlcyI6WyJ2aXNpdG9yIl0sImlhdCI6MTU1MzU5NjMwOCwiZXhwIjoxNTUzNjM5NTA4fQ.H9WWVriyvw65INuQAo29Rw9pychSNIYQjGr1WTuXFEg",
                    "Cache-Control" => "max-age=0",
                    "Connection" => "keep-alive",
                    #   "If-None-Match" => "W/\"65fe-B227HFGFKxtVZ0WCDrzCXFmnbTM\""

                }
            #   puts "#{uri} - #{initheader}"

            #   res = Net::HTTP::Options.new( uri, initheader )
            #   puts "#{res}"

            #   req = Net::HTTP::Options.new( uri, initheader )
            #   #   req['If-Modified-Since'] = file.mtime.rfc2822

            Net::HTTP.start( uri.hostname, uri.port, :use_ssl => true ) do |http|
                #   sbra = http.options( uri, initheader_options )
                #   puts "'#{sbra}' '#{sbra.message}' '#{sbra.body()}' '#{sbra.uri}'"
                #   sbra.each do |k,v|
                #       puts "#{k} => #{v}"
                #   end

                res = http.get( uri, initheader_get )
                #   puts "'#{res}' '#{res.message}' '#{res.body()}' '#{res.uri}'"
                #   res.each do |k,v|
                #       puts "#{k} => #{v}"
                #   end

                # Saving JSON data on file
                save_file = File.open( "#{DIR_WEBPAGES}/#{id}.brawlstats", "w" )
                save_file.write( res.body )
                save_file.close

                #   puts "'#{sbre}'\n'#{sbre.message}'\n'#{sbre.body()}'\n'#{sbre.uri}'"
                #   sbre.each do |k,v|
                #       puts "#{k} => #{v}"
                #   end
            end
        end

        # Reading info from the JSON data
        player_data = JSON.parse( File.read( "./#{DIR_WEBPAGES}/#{id}.brawlstats" ) )
        player_data = player_data[ "playerProfile" ]

        # Composing the info of the player
        player.id = player_data[ "hashtag" ]
        player.name = player_data[ "name" ]
        

        player.trophies.update_trophies( player_data[ "trophies" ], player_data[ "highestTrophies" ] )
        player.experience.update_total( player_data[ "totalExperience" ] )
        player.victories.update_all( [ player_data[ "winCount" ], player_data[ "showdownWinCount" ][ "solo" ], player_data[ "showdownWinCount" ][ "duo" ] ] )
        player_data[ "brawlers" ].each do |brawler|
            player.brawlers.update_brawler( brawler[ "brawlerId" ], [ brawler[ "level" ], brawler[ "currentTrophies" ], brawler[ "highestTrophies" ] ] )
        end

    end

end
