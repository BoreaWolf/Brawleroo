#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 21 Mar 2019 
# Description: Class representing a single player
#

require "date"
require "fastimage"
require "prawn"
require "squid"

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

        # Creating all data used to print afterwards
        players_data_series = Hash.new
        data_selectors = [ "trophies", "max_trophies", "other" ]
        data_selectors.each do |data_selector|
            players_data_series[ data_selector ] = Hash.new
            @player_list.each do |player|
                players_data_series[ data_selector ][ player.name ] = Hash.new
                ORDERED_CHARS.each do |char_name, _, _|
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
        data_selectors = [ "Power", "Trophies", "Max", "Rank" ]
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
                # TODO: Find a way to pass the Brawler class name from the class
                # itself and not as a typed String
                if player_progression[ CHARS[ index ][ 0 ] ][ "Power" ][ current_date ] > 0 then
                    player_progression[ CHARS[ index ][ 0 ] ][ "Rank" ][ current_date ] = Trophies.find_rank( player_progression[ CHARS[ index ][ 0 ] ][ "Max" ][ current_date ], "Brawler" )
                end
            end
        end

        # Comparisons with other players, one page per player
        # Creating a graph with all brawlers on the x-axis and their trophies on
        # the y-axis
        Prawn::Document.generate( "#{PDF_FILE_DIR}/#{get_player_name( player_id )}#{PDF_FILE_EXT}",
                                  # :page_layout => :landscape, # ) do |output_file|
                                  :page_size => PAGE_DIM ) do |output_file|

        	# Fonts
        	font_files = Dir[ "#{FONTS_DIR}/*#{FONTS_EXT}" ]
        	fonts = Array.new
        	font_files.each do |font|
        		fonts.push( [ font, font.rpartition( "/" )[2].partition( "." )[0] ] )
        	end
            
        	fonts.each do |font|
        		output_file.font_families.update(
        			font[ 1 ] => {
        				:normal =>		{ :file => font[ 0 ], :font => font[ 1 ]  },
        				:italic => 		{ :file => font[ 0 ], :font => font[ 1 ] + "-Italic" },
        				:bold =>		{ :file => font[ 0 ], :font => font[ 1 ] + "-Bold" },
        				:bold_italic =>	{ :file => font[ 0 ], :font => font[ 1 ] + "-BoldItalic" }
        			} )
        	end

            # Personal progression graphs for each brawler
            output_file.text( "#{get_player_name( player_id )}", :align => :center )

            output_file.text( "Trophies", :align => :center )
            output_file.chart( { "Trophies" => player_progression[ get_player_name( player_id ) ][ "Trophies" ] },
                               legend: false,
                               labels: [ true ] )
            output_file.start_new_page()

            # Pages for each brawler with information and progression graph
            # Boxes dimensions of these pages
            name_box_size = [ REAL_PAGE_DIM[ 0 ], REAL_PAGE_DIM[ 1 ] * RATE_BRAWLER_NAME ]
            graph_box_size = [ REAL_PAGE_DIM[ 0 ], REAL_PAGE_DIM[ 1 ] * RATE_BRAWLER_GRAPH ]
            info_box_size = [ REAL_PAGE_DIM[ 0 ], REAL_PAGE_DIM[ 1 ] * RATE_BRAWLER_INFO ]
            split_box_size = [ info_box_size[ 0 ] / 2, info_box_size[ 1 ] ]
            bubble_width = split_box_size[ 0 ] * 0.50
            bubble_height = split_box_size[ 1 ] * 0.65

            #   font_index = 0
            #   fonts = [ "Another Round", "icedrop", "tf2build", "Barnacle Boy" ]
            
            # Creating the graphs based on their ordered list
            ORDERED_CHARS.each do |char_name, char_rarity, _|

                #   output_file.font( fonts[ font_index ] )
                #   font_index = ( font_index + 1 ) % fonts.size
                output_file.font( "tf2build" )

                # Brawler name box
                output_file.bounding_box( [ 0, output_file.cursor ], :width => name_box_size[ 0 ], :height => name_box_size[ 1 ] ) do
                    output_file.pad_top( name_box_size[ 1 ] / 3 ) do
                        output_file.text( "#{char_name.upcase}", :align => :center, :size => name_box_size[ 1 ] / 2 )
                    end
                end

                # Written info box
                output_file.bounding_box( [ 0, output_file.cursor ], :width => split_box_size[ 0 ], :height => split_box_size[ 1 ] ) do
                    info_text = [ "Power Level: #{player_progression[ char_name ][ "Power" ].to_a.last()[ 1 ]}",
                                  "Current trophies: #{player_progression[ char_name ][ "Trophies" ].to_a().last()[ 1 ]}",
                                  "Max trophies: #{player_progression[ char_name ][ "Max" ].to_a().last()[ 1 ]}",
                                  "Rank: #{player_progression[ char_name ][ "Rank" ].to_a.last()[ 1 ]}" ]
                    # 1/2 of the box is free space on top and bottom
                    # The remaining half is split equally between text and pad
                    info_text_font_size = split_box_size[ 1 ] / 4 / info_text.size
                    info_text_pad = split_box_size[ 1 ] / 4 / info_text.size
                    top_space = ( split_box_size[ 1 ] + info_text.size * info_text_font_size + ( info_text.size - 1 ) * info_text_pad ) / 2

                    # Pad top works from the top of the box, so I need the
                    # complementary to what I have calculated 
                    output_file.pad_top( split_box_size[ 1 ] - top_space ) do
                        info_text.each do |text|
                            # Using pad bottom to avoid pushing everything down
                            # one unnecessary space
                            # The extra space is after the last text which is
                            # not going to be a problem, hopefully
                            output_file.pad_bottom( info_text_pad ){ output_file.text( text, :align => :center, :size => info_text_font_size ) }
                        end
                    end
                end

                # Clear font for the graphs
                output_file.font( "Helvetica" )

                # Brawler image
                output_file.bounding_box( [ split_box_size[ 0 ], REAL_PAGE_DIM[ 1 ] - name_box_size[ 1 ] ], :width => split_box_size[ 0 ], :height => split_box_size[ 1 ] ) do
                    output_file.ellipse( [ split_box_size[ 0 ] / 2, split_box_size[ 1 ] / 2 ],
                                         Math.sqrt( 2 ) * bubble_width / 2,
                                         Math.sqrt( 2 ) * bubble_height / 2 )
                    output_file.fill_color( RARITY_COLORS[ RARITY[ char_rarity ] ] )
                    output_file.fill()
                    #
                    # Reading the image original dimensions
                    #    "#{IMAGES_DIR}/hero_#{char_name.downcase}.png",
                    image_path = "#{IMAGES_DIR}/#{char_name.gsub( " ", "_" )}_Skin-Default.png"
                    image_dim = FastImage.size( image_path )
                    image_height = [ image_dim[ 1 ], Math.sqrt( 2 ) * bubble_width ].min.round
                    image_width = ( image_dim[ 0 ] * image_height / image_dim[ 1 ] ).round
                    output_file.image( image_path,
                                       :at => [ ( split_box_size[ 0 ] - image_width ) / 2, ( split_box_size[ 1 ] + image_height ) / 2 ],
                                       :width => image_width,
                                       :height => image_height )
                    output_file.fill_color( "000000" )
                end

                # Brawler progression graph
                output_file.bounding_box( [ 0, output_file.cursor ], :width => graph_box_size[ 0 ], :height => graph_box_size[ 1 ] ) do
                    output_file.pad_top( graph_box_size[ 1 ] * 0.07 ) do
                        output_file.chart( { "Max" => create_cute_hash( player_progression[ char_name ][ "Max" ] ),
                                             "Trophies" => create_cute_hash( player_progression[ char_name ][ "Trophies" ] ) },
                                           type: :line,
                                           #    type: :two_axis,
                                           line_widths: [ 1, 2 ],
                                           labels: [ true, true ],
                                           height: graph_box_size[ 1 ] * 0.8 )
                    end 

                    output_file.pad_top( graph_box_size[ 1 ] * 0.02 ) do 
                        output_file.font( "tf2build" ) do
                            output_file.text( "Trophies progression", :align => :center )
                        end
                    end
                end

                # Starting a new page for the next brawler
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
                    output_file.chart( { get_player_name( player_id ) => players_data_series[ "trophies" ][ get_player_name( player_id ) ],
                                         player.name => players_data_series[ "trophies" ][ player.name ] } )
                    #   puts "Pre caption: #{output_file.cursor}"
                    output_file.text( "Current trophies", :align => :center )
                    #   puts "Pre graph: #{output_file.cursor}"
                    output_file.chart( { get_player_name( player_id ) => players_data_series[ "max_trophies" ][ get_player_name( player_id ) ],
                                         player.name => players_data_series[ "max_trophies" ][ player.name ] },
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

                    output_file.start_new_page()
                end
            end
        end
        puts "DONE (•̀o•́)ง"
    end

    def create_cute_hash( data )
        return data.map{ |k,v| [ DateTime.parse( k ).strftime( GRAPH_TIME_FORMAT ), v ] }.to_h
    end
end
