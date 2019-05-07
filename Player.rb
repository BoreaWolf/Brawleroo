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

    def get_rank()
        return @trophies.rank
    end

    def get_level()
        return @experience.level
    end

    def get_unlocked_brawlers()
        return @brawlers.get_unlocked()
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
        return "#{name} #{to_pdf_subtitle_string()}"
    end

    def to_pdf_subtitle_string()
        return "[#{trophies.rank} @ #{trophies.trophies}]"
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
            
            #   font_index = 0
            #   fonts = [ "Another Round", "icedrop", "tf2build", "Barnacle Boy" ]

            # Pages for each brawler with information and progression graph
            # Boxes dimensions of these pages
            name_box_size = [ REAL_PAGE_DIM[ 0 ], REAL_PAGE_DIM[ 1 ] * RATE_BRAWLER_NAME ]
            graph_box_size = [ REAL_PAGE_DIM[ 0 ], REAL_PAGE_DIM[ 1 ] * RATE_BRAWLER_GRAPH ]
            info_box_size = [ REAL_PAGE_DIM[ 0 ], REAL_PAGE_DIM[ 1 ] * RATE_BRAWLER_INFO ]
            split_box_size = [ info_box_size[ 0 ] / 2, info_box_size[ 1 ] ]
            player_image_box_size = [ REAL_PAGE_DIM[ 0 ] / 4, split_box_size[ 1 ] ]

            # Personal progression graphs for each brawler
            output_file.font( "tf2build" )

            create_title_box( output_file, [ 0, output_file.cursor ], name_box_size, get_player_name( player_id ).upcase )

            info_text = [ "Player ID: ##{player_id}",
                          "Rank: #{get_player_by_id( player_id ).get_rank()}",
                          "Trophies: #{get_player_by_id( player_id ).trophies.trophies}",
                          "Exp level: #{get_player_by_id( player_id ).get_level()}",
                          "Unlocked Brawlers: #{get_player_by_id( player_id ).get_unlocked_brawlers()}/#{CHARS.size}" ]
            create_info_text_box( output_file, [ 0, output_file.cursor ], split_box_size, info_text )

            info_text = [ "Victories:",
                          "3v3: #{get_player_by_id( player_id ).victories.trio}",
                          "Duo: #{get_player_by_id( player_id ).victories.duo}",
                          "Solo: #{get_player_by_id( player_id ).victories.solo}", ]
            create_info_text_box( output_file, [ split_box_size[ 0 ], REAL_PAGE_DIM[ 1 ] - name_box_size[ 1 ] ], split_box_size, info_text )

            # TODO: Fix the image reading it from the json of the player
            create_image_box( output_file,
                              [ ( REAL_PAGE_DIM[ 0 ] - player_image_box_size[ 0 ] ) / 2, REAL_PAGE_DIM[ 1 ] - name_box_size[ 1 ] ],
                              player_image_box_size,
                              "FFFFFF",
                              "#{IMAGES_DIR}/#{get_player_by_id( player_id ).image}#{BRAWLER_ICON_EXT}",
                              0.5 )

            # Trophies progression of the player
            graph_data = { "Trophies" => create_cute_hash( player_progression[ get_player_name( player_id ) ][ "Trophies" ] ) }
            create_graph_box( output_file, [ 0, output_file.cursor ], graph_box_size, graph_data, "Trophies", [ true ], false )

            output_file.start_new_page()

            # Creating the graphs based on their ordered list
            ORDERED_CHARS.each do |char_name, char_rarity, _|

                #   output_file.font( fonts[ font_index ] )
                #   font_index = ( font_index + 1 ) % fonts.size
                output_file.font( "tf2build" )

                # Brawler name box
                create_title_box( output_file, [ 0, output_file.cursor ], name_box_size, char_name.upcase )

                # Written info box
                info_text = [ "Power Level: #{player_progression[ char_name ][ "Power" ].to_a.last()[ 1 ]}",
                              "Current trophies: #{player_progression[ char_name ][ "Trophies" ].to_a().last()[ 1 ]}",
                              "Max trophies: #{player_progression[ char_name ][ "Max" ].to_a().last()[ 1 ]}",
                              "Rank: #{player_progression[ char_name ][ "Rank" ].to_a.last()[ 1 ]}" ]
                create_info_text_box( output_file, [ 0, output_file.cursor ], split_box_size, info_text )

                # Brawler image
                create_image_box( output_file, [ split_box_size[ 0 ], REAL_PAGE_DIM[ 1 ] - name_box_size[ 1 ] ],
                                  split_box_size,
                                  RARITY_COLORS[ RARITY[ char_rarity ] ],
                                  "#{IMAGES_DIR}/#{char_name.gsub( " ", "_" )}_Skin-Default.png" )

                # Brawler progression graph
                graph_data = { "Max" => create_cute_hash( player_progression[ char_name ][ "Max" ] ),
                               "Trophies" => create_cute_hash( player_progression[ char_name ][ "Trophies" ] ) }
                create_graph_box( output_file, [ 0, output_file.cursor ], graph_box_size, graph_data, "Trophies progression", [ true, true ], true, :line, [ 1, 2 ] )

                # Starting a new page for the next brawler
                output_file.start_new_page()
            end

            # Cycling on the players and making comparisons between them
            @player_list.each_with_index do |player, i|
                if player.id != player_id then

                    # Creating a two lines title
                    create_title_box( output_file, [ 0, output_file.cursor ], name_box_size, "#{get_player_by_id( player_id ).name} vs. #{player.name}" )
                    create_title_box( output_file, [ 0, output_file.cursor + name_box_size[ 1 ] / 3 ],
                                     [ name_box_size[ 0 ], name_box_size[ 1 ] / 2 ],
                                     "#{get_player_by_id( player_id ).to_pdf_title_string()} vs. #{player.to_pdf_subtitle_string()}" )

                    graph_data = { get_player_name( player_id ) => players_data_series[ "trophies" ][ get_player_name( player_id ) ],
                                   player.name => players_data_series[ "trophies" ][ player.name ] }
                    create_graph_box( output_file, [ 0, output_file.cursor ], graph_box_size, graph_data, "Current Trophies", [ false, false ], true )

                    #   puts "Pre graph: #{output_file.cursor}"
                    graph_data = { get_player_name( player_id ) => players_data_series[ "max_trophies" ][ get_player_name( player_id ) ],
                                   player.name => players_data_series[ "max_trophies" ][ player.name ] }
                    create_graph_box( output_file, [ 0, output_file.cursor ], graph_box_size, graph_data, "Max trophies", [ true, true ], false, :line, [ 2, 2 ] )

                    # Creating a new page only if there is a new player to show
                    if ( i + 1 ) < @player_list.size then
                        output_file.start_new_page()
                    end
                end
            end
        end
        puts "DONE (•̀o•́)ง"
    end

    def create_cute_hash( data )
        return data.map{ |k,v| [ DateTime.parse( k ).strftime( GRAPH_TIME_FORMAT ), v ] }.to_h
    end

    # Written info box
    def create_info_text_box( output_file, starting_point, dimension, info_text )
        output_file.bounding_box( starting_point, :width => dimension[ 0 ], :height => dimension[ 1 ] ) do
            # 1/2 of the box is free space on top and bottom
            # The remaining half is split equally between text and pad
            info_text_font_size = dimension[ 1 ] / 4 / info_text.size
            info_text_pad = dimension[ 1 ] / 4 / info_text.size
            top_space = ( dimension[ 1 ] + info_text.size * info_text_font_size + ( info_text.size - 1 ) * info_text_pad ) / 2

            # Pad top works from the top of the box, so I need the
            # complementary to what I have calculated 
            output_file.pad_top( dimension[ 1 ] - top_space ) do
                info_text.each do |text|
                    # Using pad bottom to avoid pushing everything down
                    # one unnecessary space
                    # The extra space is after the last text which is
                    # not going to be a problem, hopefully
                    output_file.pad_bottom( info_text_pad ){ output_file.text( text, :align => :center, :size => info_text_font_size ) }
                end
            end
        end
    end

    # Title box
    def create_title_box( output_file, starting_point, dimension, title )
        output_file.bounding_box( starting_point, :width => dimension[ 0 ], :height => dimension[ 1 ] ) do
            output_file.pad_top( dimension[ 1 ] / 3 ) do
                output_file.text( "#{title}", :align => :center, :size => dimension[ 1 ] / 2 )
            end
        end
    end

    def create_graph_box( output_file,
                          starting_point,
                          dimension,
                          graph_data,
                          graph_caption,
                          graph_labels = [ false ] * graph_data.size,
                          graph_legend = true,
                          graph_type = :column,
                          graph_line_widths = [ 1 ] * graph_data.size,
                          graph_font = "Helvetica" )
        output_file.bounding_box( starting_point, :width => dimension[ 0 ], :height => dimension[ 1 ] ) do
            output_file.pad_top( dimension[ 1 ] * 0.07 ) do
                output_file.font( graph_font ) do
                    output_file.chart( graph_data,
                                       type: graph_type,
                                       line_widths: graph_line_widths,
                                       labels: graph_labels,
                                       legend: graph_legend,
                                       height: dimension[ 1 ] * 0.8 )
                end
            end 

            # Graph label
            output_file.pad_top( dimension[ 1 ] * 0.02 ) do 
                output_file.text( graph_caption, :align => :center )
            end
        end
    end

    def create_image_box( output_file, starting_point, dimension, bubble_color, image_path, transparency = 1.0 )
        bubble_width = dimension[ 0 ] * 0.50
        bubble_height = dimension[ 1 ] * 0.65
        previous_fill_color = output_file.fill_color()
        
        output_file.bounding_box( starting_point, :width => dimension[ 0 ], :height => dimension[ 1 ] ) do
            output_file.transparent( transparency ) do 
                output_file.ellipse( [ dimension[ 0 ] / 2, dimension[ 1 ] / 2 ],
                                     Math.sqrt( 2 ) * bubble_width / 2,
                                     Math.sqrt( 2 ) * bubble_height / 2 )
                output_file.fill_color( bubble_color )
                output_file.fill()
                #
                # Reading the image original dimensions
                #    "#{IMAGES_DIR}/hero_#{char_name.downcase}.png",
                image_dim = FastImage.size( image_path )
                image_height = [ image_dim[ 1 ], Math.sqrt( 2 ) * bubble_width ].min.round
                image_width = ( image_dim[ 0 ] * image_height / image_dim[ 1 ] ).round
                output_file.image( image_path,
                                   :at => [ ( dimension[ 0 ] - image_width ) / 2, ( dimension[ 1 ] + image_height ) / 2 ],
                                   :width => image_width,
                                   :height => image_height )
                output_file.fill_color( previous_fill_color )
            end
        end
    end
end
