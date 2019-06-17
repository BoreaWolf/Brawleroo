#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 21 Mar 2019
# Description: Functions to read data from different websites
#

require "json"
require "nokogiri"
require "net/http"
require "open-uri"
require "time"
require "uri"

require "selenium-webdriver"

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
        if online or not File.exists?( "#{DIR_WEBPAGES}/#{id}.brawlstats" ) then
            save_player_data_locally( id )
        end

        puts "Reading info about player #{id}..."

        # Reading info from the JSON data
        player_data = JSON.parse( File.read( "./#{DIR_WEBPAGES}/#{id}.brawlstats" ) )

        # Trying to update the profile for three times max to gather his info
        tries = 0
        while not player_data.key?( "playerProfile" ) and tries < 3 
            save_player_data_locally( id )
            player_data = JSON.parse( File.read( "./#{DIR_WEBPAGES}/#{id}.brawlstats" ) )
            # Avoiding to show myself again, so changing token identifier
            if player_data and player_data.key?( "status" ) and player_data[ "status" ] == 429 then
                save_player_data_locally( id, true )
                player_data = JSON.parse( File.read( "./#{DIR_WEBPAGES}/#{id}.brawlstats" ) )
            end
            tries += 1
        end

        # If the player data is still does not have 
        if not player_data.key?( "playerProfile" ) then
            puts "read_stats_brawlstats::ERROR while reading #{id} player profile after trying #{tries} times."
            exit( -1 )
        end

        player_data = player_data[ "playerProfile" ]

        # Composing the info of the player
        player.id = player_data[ "hashtag" ]
        #   player.name = player_data[ "name" ]
        # TODO: Temporary fix for extra font characters that cannot be
        # represented in a pdf with easy font/encoding
        player.name = ""
        player_data[ "name" ].split( "" ).each do |char|
            # If the character bytes are longer than one then the character is
            # special and requires special font to be represented in a pdf file
            if char.bytes.length == 1 then
                player.name += char
            end
        end
        # If the name is empty, all characters have benn removed, then I use the
        # tag surrounded by angle brackets <>
        player.name = "<#{player.id}>" if player.name.empty?

        player.image = player_data[ "avatarId" ]
        if not File.exists?( "#{IMAGES_DIR}/#{player.image}#{BRAWLER_ICON_EXT}" ) then
            puts "Downloading avatar of #{player.name}##{player.id}(#{player.image})"
            save_player_icon( player.image )
        end

        player.trophies.update_trophies( player_data[ "trophies" ], player_data[ "highestTrophies" ], player.class.name )
        player.experience.update_total( player_data[ "totalExperience" ] )
        player.victories.update_all( [ player_data[ "winCount" ], player_data[ "showdownWinCount" ][ "solo" ], player_data[ "showdownWinCount" ][ "duo" ] ] )
        player_data[ "brawlers" ].each do |brawler|
            player.brawlers.update_brawler( brawler[ "brawlerId" ], [ brawler[ "level" ], brawler[ "currentTrophies" ], brawler[ "highestTrophies" ] ] )
        end
    end

    def save_player_data_locally( id, force_token = false )
        puts "Saving locally information about player #{id} [forcing token #{force_token}]..."

        uri = URI( "#{WEBSITE_BRAWLSTATS_API}/#{id}" )
        # Request headers
        initheader_get =
            {
                "Accept" => "application/json",
                "Accept-Encoding" => "deflate",
                "Accept-Language" => "en-GB,en;q=0.5",
                "Authorization" => "Bearer #{get_token( force_token )}",
                "Cache-Control" => "max-age=0",
                "Connection" => "keep-alive"
                #   "If-None-Match" => "W/\"8d21-gZoGlc23SWuTVuI9b/BOGP4IAl4"
            }

        Net::HTTP.start( uri.hostname, uri.port, :use_ssl => true ) do |http|
            # Requesting the page with the generated header
            res = http.get( uri, initheader_get )

            # Saving JSON data on file
            File.open( "#{DIR_WEBPAGES}/#{id}.brawlstats", "w" ) do |save_file|
                save_file.write( res.body )
            end
        end
    end

    def get_token( force_token )
        # Forcing a new token from the website
        if force_token then
            token = fetch_token()
            save_local_token( token )
        else
            # Reading the local token file if it is expired then I will get a
            # new one
            token = load_local_token()
            unless token then
                token = fetch_token()
                fail unless token
                save_local_token( token )
            end
        end
        token
    end

    def save_player_icon( badge_id )
        print "Saving icon #{badge_id}."
        puts "'#{WEBSITE_BRAWLSTATS_ICONS}/#{badge_id}#{BRAWLER_ICON_EXT}'"
        open( "#{WEBSITE_BRAWLSTATS_ICONS}/#{badge_id}#{BRAWLER_ICON_EXT}" ) do |image_link|
            File.open( "#{IMAGES_DIR}/#{badge_id}#{BRAWLER_ICON_EXT}", "w" ) do |image|
                image.puts( image_link.read() )
            end
        end
        puts "...DONE o(^▽^)o"
    end

private

    def fetch_token()
        # Opening the webpage to let it create the token needed to get
        # authenticated from the server
        begin
            driver = Selenium::WebDriver.for :firefox #assuming you're using firefox
            driver.get( WEBSITE_BRAWLSTATS )
            driver.manage.cookie_named( "token" )[ :value ]
        ensure
            driver.quit
        end
    end

    def load_local_token()
        return if not File.exist?( TOKEN_LOCAL_FILE )
        File.open( TOKEN_LOCAL_FILE, "r" ) do |token_file|
            expiry_line = token_file.gets()
            return if expiry_line.nil?
            return if Time.parse( expiry_line ) < Time.now()
            # Reading the second line of the file and returning the requested token
            token_file.gets()
        end
    end

    def save_local_token( token )
        File.open( TOKEN_LOCAL_FILE, "w" ) do |token_file|
            token_file.puts "#{Time.now() + TOKEN_EXPIRE_TIME}"
            token_file.puts "#{token}"
        end
    end
end
