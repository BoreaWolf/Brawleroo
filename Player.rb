#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 21 Mar 2019 
# Description: Class representing a single player
#

require "squid"
require "prawn"

require "./Constants.rb"
require "./Trophies.rb"
require "./Experience.rb"
require "./Victories.rb"
require "./Brawler.rb"
require "./WebsiteInspector.rb"

class Player

    attr_accessor :id, :name, :image, :trophies, :experience, :victories, :brawlers

    def initialize( id )
        @id = id
        @name = ""
        @image = ""
        @trophies = Trophies.new()
        @experience = Experience.new()
        @victories = Victories.new()
        @brawlers = Brawlers.new()
    end

    def read_stats( online = false )
        inspector = WebsiteInspector.new()
        #   inspector.read_stats_brawland( id, self )
        inspector.read_stats_brawlstats( @id, self, online )
    end

    def get_brawler( name )
        @brawlers.get_brawler( name )
    end

    def printable()
        result = "#{@name} (##{@id})\n"
        result += @experience.printable() + "\n"
        result += @trophies.printable() + "\n"
        result += @victories.printable() + "\n"
        result += @brawlers.printable() + "\n"
        return result
    end

    def printable_intro()
        return "#{@name} (##{@id}) #{@trophies.printable()}"
    end

    def update_csv_stats()
        # Looking for the player file, if it doesn't exist it will get created
        # Opening the file with append does what I need without checking the
        # existence of the file
        
        # I could avoid printing the name and tag since the file is personal of
        # that player, but in this way I have data format consistence through
        # all the files
        File.open( "#{EXPORT_FILE_DIR}/#{id}#{EXPORT_FILE_EXT}", "a" ) do |export_file|
            export_file.write( "#{Time.now.strftime( "%Y/%m/%d_%H:%M" )}\t#{export_to_csv()}\n" )
        end
    end

    def export_to_csv()
        result = "#{name}\t#{id}\t#{trophies.export_to_csv()}\t"
        result += "#{victories.export_to_csv()}\t"
        result += "#{brawlers.export_to_csv()}"
        return result
    end

    def to_pdf_title_string()
        return "#{name} [#{trophies.rank} @ #{trophies.trophies}]"
    end
end

class Players
    def initialize( ids )
        @player_list = Array.new()
        ids.each do |id|
            @player_list.append( Player.new( id ) )
            @player_list[ -1 ].read_stats()
        end
    end

    def update_stats()
        @player_list.each{ |player| player.read_stats( true ) }
    end

    def get_player_by_name( name )
        @player_list.each do |player|
            if player.name == name then
                return player
            end
        end
        return "Player not found."
    end

    def get_player_by_id( id )
        @player_list.each do |player|
            if player.id == id then
                return player
            end
        end
        return "Player not found."
    end

    def get_player_name( id )
        return get_player_by_id( id ).name
    end

    # Comparing all players to the given one
    def compare_to( id )
        player_comparisons = Array.new()
        ref_player = get_player_by_id( id )
        @player_list.each do |player|
            if player.id != id then
                compared = Player.new( "#{id}-##{player.id}" )
                compared.name = "#{ref_player.name} vs #{player.name}"
                compared.trophies = Trophies.compare( ref_player.trophies, player.trophies )
                compared.experience = Experience.compare( ref_player.experience, player.experience )
                compared.victories = Victories.compare( ref_player.victories, player.victories )
                compared.brawlers = Brawlers.compare( ref_player.brawlers, player.brawlers )

                player_comparisons.append( compared )
            end
        end
        return player_comparisons
    end

    def printable_intro()
        result = "Player list:\n"
        @player_list.each do |player|
            result +=  " - " + player.printable_intro() + "\n"
        end
        return result
    end

    def printable_full()
        result = "Player list:\n"
        @player_list.each do |player|
            result +=  " => " + player.printable() + "\n"
        end
        return result
    end

    def update_players_csv_stats()
        print "Updating players stats."
        @player_list.each do |player|
            player.update_csv_stats()
            print "."
        end
        puts "DONE (•̀o•́)ง"
    end

    def export_to_csv()
        print "Exporting data to '#{EXPORT_FILE_DIR}/#{EXPORT_FILE_NAME}#{EXPORT_FILE_EXT}'..."
        File.open( "#{EXPORT_FILE_DIR}/#{EXPORT_FILE_NAME}#{EXPORT_FILE_EXT}", "w" ) do |export_file|
            # Writing the header as first line of the document
            export_file.write( "#{EXPORT_FILE_HEADER_LINE}" )
            @player_list.each do |player|
                export_file.write( "#{player.export_to_csv()}\n" )
            end
        end
        puts "DONE (•̀o•́)ง"
    end

    def create_graphs( player_id )
        print "Creating cute graphs for the player '#{player_id}'..."

        # Ordering the brawlers based on their rarity first and on their id
        # afterwards
        # Useful to have clean graphs based on the rarity of the brawlers
        ordered_chars = CHARS.sort_by{ |char| [ char[ 1 ], char[ 2 ] ] }

        # Creating all data used to print afterwards
        players_data_series = Hash.new
        data_selectors = [ "trophies", "max_trophies", "other" ]
        data_selectors.each do |data_selector|
            players_data_series[ data_selector ] = Hash.new
            @player_list.each do |player|
                players_data_series[ data_selector ][ player.name ] = Hash.new
                ordered_chars.each do |char_name, _, _|
                    case data_selector
                    when "trophies"
                        players_data_series[ data_selector ][ player.name ][ char_name ] = player.get_brawler( char_name ).trophies.trophies
                    when "max_trophies"
                        players_data_series[ data_selector ][ player.name ][ char_name ] = player.get_brawler( char_name ).trophies.max_trophies
                    end
                end
            end
        end
        
        # Player page

        # Personal progression graphs
        # Reading the file of the player
        # Each line of the file corresponds to a day of data
        # Need to create an array of characters with the data dividede by day
        data_selectors = [ "Rank", "Trophies", "Max" ]
        char_names = [ get_player_name( player_id ), CHARS.map{ |x| x[ 0 ] } ].flatten
        player_progression = Hash.new
        char_names.each do |char_name|
            player_progression[ char_name ] = Hash.new
            data_selectors.each do |data_selector|
                player_progression[ char_name ][ data_selector ] = Hash.new
            end
        end

        # NOTE: The problem is probably the labels being too long and unable to
        # fit more than 15 in the same page
        # The graphs can contain a maximum of 15 data elements on the x-axis
        # I will only read the last 15 lines of the file using a unix command
        # and then splitting the returned string into an array of the lines
        lines = `tail -n #{LINES_TO_READ} #{EXPORT_FILE_DIR}/#{player_id}#{EXPORT_FILE_EXT}`
        #   File.open( "#{EXPORT_FILE_DIR}/#{player_id}#{EXPORT_FILE_EXT}", "r" ).each do |daily_line|
        lines.split( "\n" ).each do |daily_line|
            daily_data = daily_line.match( REGEX_FILE_LINE_STATS )
            # If I leave only the date, updates happening on the same day will
            # be ignored
            #   current_date = daily_data[ 1 ].match( REGEX_DATE_ONLY )[ 0 ]
            current_date = daily_data[ 1 ]
            char_names.each do |char_name|
                data_selectors.each do |data_selector|
                    player_progression[ char_name ][ data_selector ][ current_date ] = 0
                end
            end

            # Working only on the third match of the daily data
            # TODO: Player rank is not correct at the moment
            # When reading the data from file I have to keep the order of the
            # CHARS structure to respect eventual new brawlers and not confuse
            # their data with others
            daily_data[ 3 ].scan( REGEX_FILE_LINE_CHAR_STATS ).each_with_index do |char_data, index|
                char_data.each_with_index do |char_stat, j|
                    player_progression[ CHARS[ index ][ 0 ] ][ data_selectors[ j ] ][ current_date ] = char_stat.to_i
                    player_progression[ get_player_name( player_id ) ][ data_selectors[ j ] ][ current_date ] += char_stat.to_i
                end
            end
        end

        # Comparisons with other players, one page per player
        # Creating a graph with all brawlers on the x-axis and their trophies on
        # the y-axis
        Prawn::Document.generate( "#{PDF_FILE_DIR}/#{get_player_name( player_id )}#{PDF_FILE_EXT}",
                                  # :page_layout => :landscape, # ) do |output_file|
                                  :page_size => PAGE_DIM ) do |output_file|

            # Personal progression graphs for each brawler
            output_file.text( "#{get_player_name( player_id )}", :align => :center )

            output_file.text( "Trophies", :align => :center )
            output_file.chart( { "Trophies" => player_progression[ get_player_name( player_id ) ][ "Trophies" ] },
                               legend: false,
                               labels: [ true ] )
            output_file.start_new_page()

            # Creating the graphs based on their ordered list
            # TODO: Add the picture of the brawler before the graph
            ordered_chars.each do |char_name, _, _|
                #   output_file.text( "#{char_name} - Rank: #{player_progression[ char_name ][ "Rank" ].to_a.last()[ 1 ] }", :align => :left )
                output_file.text( "#{char_name}", :align => :center )

                info_box_size = [ REAL_PAGE_DIM[ 0 ], REAL_PAGE_DIM[ 1 ] * RATE_BRAWLER_INFO ]
                puts "#{info_box_size}"

                output_file.fill_color( "111111" )
                output_file.circle( [ 0, output_file.cursor ], 5 )
                output_file.fill_color( "333333" )
                output_file.fill_and_stroke_rectangle( [ 0, output_file.cursor ], info_box_size[ 0 ], info_box_size[ 1 ] )

                output_file.bounding_box( [ 0, output_file.cursor ], :width => info_box_size[ 0 ], :height => info_box_size[ 1 ] ) do
                    info_text_size = [ info_box_size[ 0 ] / 2, info_box_size[ 1 ] ]
                    output_file.fill_color( "888888" )
                    output_file.fill_and_stroke_rectangle( [ 0, output_file.cursor ], info_text_size[ 0 ], info_text_size[ 1 ] )
                    output_file.fill_color( "000000" )

                    output_file.bounding_box( [ 0, output_file.cursor ], :width => info_text_size[ 0 ], :height => info_text_size[ 1 ] ) do
                        output_file.text( "Rank: #{player_progression[ char_name ][ "Rank" ].to_a.last()[ 1 ]}", :align => :center )
                        output_file.text( "Current trophies: #{player_progression[ char_name ][ "Trophies" ].to_a().last()[ 1 ]}", :align => :center )
                        output_file.text( "Max trophies: #{player_progression[ char_name ][ "Max" ].to_a().last()[ 1 ]}", :align => :center )
                    end
                    info_image_size = [ info_box_size[ 0 ] / 2, info_box_size[ 1 ] ]
                    output_file.fill_color( "FF0000" )
                    output_file.fill_and_stroke_rectangle( [ 0 + info_text_size[ 0 ], output_file.cursor ], info_image_size[ 0 ], info_image_size[ 1 ] )
                    output_file.bounding_box( [ 0, output_file.cursor + info_text_size[ 1 ] ], :width => info_image_size[ 0 ], :height => info_image_size[ 1 ]  ) do 
                        if char_name == "Jessie" then
                            output_file.image( "#{IMAGES_DIR}/#{char_name}.png", :position => :right, :width => 146 )
                        end
                    end
                end


                output_file.chart( { "Max" => player_progression[ char_name ][ "Max" ], "Trophies" => player_progression[ char_name ][ "Trophies" ] },
                                   type: :line,
                                   #    type: :two_axis,
                                   line_widths: [ 1, 2 ],
                                   labels: [ true, true ] )
                output_file.start_new_page()
            end

            # Cycling on the brawlers
            # data = { player_id => { x => y, ... }, ... }
            @player_list.each do |player|
                if player.id != player_id then
                    #   puts "Pre title: #{output_file.cursor} #{output_file.cursor.class}"
                    #   output_file.text( "#{get_player_name( player_id )} [#{get_player_by_id( player_id ).trophies.trophies}] vs. #{player.name} [#{player.trophies.trophies}]", :align => :center )
                    output_file.text( "#{get_player_by_id( player_id ).to_pdf_title_string()} vs. #{player.to_pdf_title_string()}", :align => :center )

                    # Too many not relevant information in this graph
                    #   output_file.chart( players_data_series[ "other" ].select{ |k,v| k == get_player_name( player_id ) or k == player.name } )
                    #   output_file.text( "General stats", :align => :center )

                    #   puts "Pre graph: #{output_file.cursor}"
                    output_file.chart( players_data_series[ "trophies" ].select{ |k,v| k == get_player_name( player_id ) or k == player.name } )
                    #   puts "Pre caption: #{output_file.cursor}"
                    output_file.text( "Current trophies", :align => :center )
                    #   puts "Pre graph: #{output_file.cursor}"
                    output_file.chart( players_data_series[ "max_trophies" ].select{ |k,v| k == get_player_name( player_id ) or k == player.name },
                                       type: :line,
                                       line_widths: [ 2, 2 ],
                                       labels: [ true, true ],
                                       legend: false )
                    #   puts "Pre caption: #{output_file.cursor}"
                    output_file.text( "Max trophies", :align => :center )
                    #   puts "End page: #{output_file.cursor}"
                    #   output_file.start_new_page()
                    #   puts "New page: #{output_file.cursor}"
                    
                    # TODO: This library does not allow me to choose the type of
                    # style for each data series. Fix it to create a single
                    # graph with all the information in it, only if the result
                    # is not too messy.
                    #   output_data = Hash.new
                    #   #   settings = { "type" => { :stack, :line, :point, :point }, "labels" => { false, false, true, true } }
                    #   data_selectors.each do |data_selector|
                    #       #   puts "Merging #{data_selector}"
                    #       #   composing = players_data_series[ data_selector ].select{ |k, v| k == get_player_name( player_id ) or k == player.name }
                    #       #   composing = composing.map{ |k, v| composing[ "max#{k}" ] = v }
                    #       #   puts "#{composing}"
                    #       if data_selector.include?( "max" ) then
                    #           output_data[ "max#{player.name}" ] = players_data_series[ data_selector ][ player.name ]
                    #           output_data[ "max#{get_player_name( player_id )}" ] = players_data_series[ data_selector ][ get_player_name( player_id ) ]
                    #       else
                    #           output_data.merge!( players_data_series[ data_selector ].select{ |k, v| k == get_player_name( player_id ) or k == player.name } )
                    #       end
                    #   end

                    #   output_file.chart( output_data,
                    #                      type: [ :line, :line, :point, :point ],
                    #                      line_widths: [ 2, 2, 1, 1 ],
                    #                      labels: [ false, false, true, true ] )

                    #   output_file.start_new_page()
                end
            end
        end
        puts "DONE (•̀o•́)ง"
    end
end
