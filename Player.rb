#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 21 Mar 2019
# Description: Class representing a single player
#

require "date"
require "fastimage"
require "json"
require "prawn"
require "prawn/table"
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
        @trophies.rank
    end

    def get_level()
        @experience.level
    end

    def get_unlocked_brawlers()
        @brawlers.get_unlocked()
    end

    def printable()
        result = "#{@name} (##{@id})\n"
        result += @experience.printable() + "\n"
        result += @trophies.printable() + "\n"
        result += @victories.printable() + "\n"
        result += @brawlers.printable() + "\n"
        result
    end

    def printable_intro()
        "#{@name} (##{@id}) #{@trophies.printable()}"
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
    
    def update_file_stats()
        current_data = {}
        if File.exists?( "#{EXPORT_FILE_DIR}/#{id}#{EXPORT_FILE_JSON_EXT}" ) then
            current_data = JSON.parse( File.read( "#{EXPORT_FILE_DIR}/#{id}#{EXPORT_FILE_JSON_EXT}" ) )
        end
        current_data[ Time.now.strftime( EXPORT_FILE_TIME_FORMAT ) ] = export_to_json()
        
        File.open( "#{EXPORT_FILE_DIR}/#{id}#{EXPORT_FILE_JSON_EXT}", "w" ).write( JSON.generate( current_data ) )
    end

    def export_to_csv()
        result = "#{name}\t#{id}\t#{trophies.export_to_csv()}\t"
        result += "#{victories.export_to_csv()}\t"
        result += "#{brawlers.export_to_csv()}"
        result
    end

    def export_to_json()
        # I need to create the json structure for the player
        result = {}
        result[ "id" ] = @id
        result[ "name" ] = @name
        result[ "image" ] = @image
        result[ "experience" ] = @experience.export_to_json()
        result[ "trophies" ] = @trophies.export_to_json()
        result[ "victories" ] = @victories.export_to_json()
        result[ "brawlers" ] = @brawlers.export_to_json()
        return result
    end

    def to_pdf_title_string()
        "#{name} #{to_pdf_subtitle_string()}"
    end

    def to_pdf_subtitle_string()
        "[#{trophies.rank} @ #{trophies.trophies}]"
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
        @player_list.find{ |player| player.name == name }
    end

    def get_player_by_id( id )
        @player_list.find{ |player| player.id == id }
    end

    # Comparing all players to the given one
    def compare_to( id )
        ref_player = get_player_by_id( id )
        return if ref_player.nil?
        @player_list
          .select { |player| player.id != id }
          .collect do |player|
            compared = Player.new( "#{id}-##{player.id}" )
            compared.name = "#{ref_player.name} vs #{player.name}"
            compared.trophies = Trophies.compare( ref_player.trophies, player.trophies )
            compared.experience = Experience.compare( ref_player.experience, player.experience )
            compared.victories = Victories.compare( ref_player.victories, player.victories )
            compared.brawlers = Brawlers.compare( ref_player.brawlers, player.brawlers )
            compared
        end
    end

    def printable_intro()
        @player_list.inject("Player list:\n") do |result, player|
            result + " - " + player.printable_intro() + "\n"
        end
    end

    def printable_full()
        @player_list.inject("Player list:\n") do |result, player|
            result + " - " + player.printable() + "\n"
        end
    end

    def update_players_csv_stats()
        print "Updating players stats."
        @player_list.each do |player|
            player.update_csv_stats()
            print "."
        end
        puts "DONE (•̀o•́)ง"
    end

    def update_players_file_stats()
        print "Updating players stats."
        @player_list.each do |player|
            player.update_file_stats()
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
        ref_player = get_player_by_id( player_id )
        if ref_player.nil? then
            print "Player not found."
            return
        end

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
        # Need to create an array of characters with the data divided by day
        data_selectors = [ "Power", "Trophies", "Max_Trophies", "Rank" ]
        char_ids = CHARS.map{ |x| x[ 2 ] }
        player_progression = Hash.new
        [ ref_player.name, char_ids ].flatten.each do |char_name|
            player_progression[ char_name ] = Hash.new
            data_selectors.each do |data_selector|
                player_progression[ char_name ][ data_selector ] = Hash.new
            end
        end

        # Reading the progression of the player from his json file 
        player_json_data = JSON.parse( File.read( "#{EXPORT_FILE_DIR}/#{player_id}#{EXPORT_FILE_JSON_EXT}" ) )
        # I need to restrict the data to a maximum of 15 days, therefore I only
        # take in consideration the 15 more recent updates
        dates = player_json_data.keys
        if dates.size > DAYS_TO_PRINT then
            dates = player_json_data.keys.sort[ -DAYS_TO_PRINT..player_json_data.keys.size ]
        end
        dates.each do |current_date|
            # Finding info of the player
            data_selectors.select{ |x| x != "Power" }.each do |data_selector|
                player_progression[ ref_player.name ][ data_selector ][ current_date ] = player_json_data[ current_date ][ "trophies" ][ data_selector.downcase ]
            end

            # Finding the info of each brawler
            char_ids.each do |char_id|
                # Checking if the data is there for all brawlers
                # When new brawlers are added to the game there is no history of
                # them so I set them to all 0s
                if player_json_data[ current_date ][ "brawlers" ][ char_id.to_s ].nil? then
                    data_selectors.each do |data_selector|
                        player_progression[ char_id ][ data_selector ][ current_date ] = 0
                    end
                else
                    player_progression[ char_id ][ "Power" ][ current_date ] = player_json_data[ current_date ][ "brawlers" ][ char_id.to_s ][ "power" ]
                    data_selectors.select{ |x| x != "Power" }.each do |data_selector|
                        player_progression[ char_id ][ data_selector ][ current_date ] = player_json_data[ current_date ][ "brawlers" ][ char_id.to_s ][ "trophies" ][ data_selector.downcase ]
                    end
                end
            end
        end

        # Comparisons with other players, one page per player
        # Creating a graph with all brawlers on the x-axis and their trophies on
        # the y-axis
        Prawn::Document.generate( "#{PDF_FILE_DIR}/#{ref_player.name}#{PDF_FILE_EXT}",
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
            table_box_size = [ REAL_PAGE_DIM[ 0 ], PAGE_DIM[ 1 ] * RATE_TABLE_COMPARISON ]

            # Personal progression graphs for each brawler
            output_file.font( "tf2build" )

            create_title_box( output_file, [ 0, output_file.cursor ], name_box_size, ref_player.name.upcase )

            info_text = [ "Player ID: ##{player_id}",
                          "Rank: #{ref_player.get_rank()}",
                          "Trophies: #{ref_player.trophies.trophies}",
                          "Exp level: #{ref_player.get_level()}",
                          "Unlocked Brawlers: #{ref_player.get_unlocked_brawlers()}/#{CHARS.size}" ]
            create_info_text_box( output_file, [ 0, output_file.cursor ], split_box_size, info_text )

            info_text = [ "Victories:",
                          "3v3: #{ref_player.victories.trio}",
                          "Duo: #{ref_player.victories.duo}",
                          "Solo: #{ref_player.victories.solo}", ]
            create_info_text_box( output_file, [ split_box_size[ 0 ], REAL_PAGE_DIM[ 1 ] - name_box_size[ 1 ] ], split_box_size, info_text )

            create_image_box( output_file,
                              [ ( REAL_PAGE_DIM[ 0 ] - player_image_box_size[ 0 ] ) / 2, REAL_PAGE_DIM[ 1 ] - name_box_size[ 1 ] ],
                              player_image_box_size,
                              "FFFFFF",
                              "#{IMAGES_DIR}/#{ref_player.image}#{BRAWLER_ICON_EXT}",
                              0.5 )

            # Trophies progression of the player
            graph_data = { "Trophies" => create_cute_hash( player_progression[ ref_player.name ][ "Trophies" ] ) }
            create_graph_box( output_file, [ 0, output_file.cursor ], graph_box_size, graph_data, "Trophies", [ true ], false )

            output_file.start_new_page()

            # Creating the graphs based on their ordered list
            ORDERED_CHARS.each do |char_name, char_rarity, char_id|

                #   output_file.font( fonts[ font_index ] )
                #   font_index = ( font_index + 1 ) % fonts.size
                output_file.font( "tf2build" )

                # Brawler name box
                create_title_box( output_file, [ 0, output_file.cursor ], name_box_size, char_name.upcase )

                # Written info box
                # This DOES NOT work on 
                difference = player_progression[ char_id ][ "Trophies" ].to_a().reverse()[ 0..1 ].map{ |x| x[ 1 ] }
                difference = difference[ 0 ] - difference[ 1 ] if difference.size() == 2
                info_text = [ "Power Level: #{player_progression[ char_id ][ "Power" ].to_a.last()[ 1 ]}",
                              "Current trophies: #{player_progression[ char_id ][ "Trophies" ].to_a().last()[ 1 ]}",
                              "Max trophies: #{player_progression[ char_id ][ "Max_Trophies" ].to_a().last()[ 1 ]}",
                              "Rank: #{player_progression[ char_id ][ "Rank" ].to_a.last()[ 1 ]}",
                              "Last progression: #{"+" if difference > 0}#{difference}" ]
                create_info_text_box( output_file, [ 0, output_file.cursor ], split_box_size, info_text )

                # Brawler image
                create_image_box( output_file, [ split_box_size[ 0 ], REAL_PAGE_DIM[ 1 ] - name_box_size[ 1 ] ],
                                  split_box_size,
                                  RARITY_COLORS[ RARITY[ char_rarity ] ],
                                  "#{IMAGES_DIR}/#{char_name.gsub( " ", "_" )}_Skin-Default.png" )

                # Brawler progression graph
                graph_data = { "Max" => create_cute_hash( player_progression[ char_id ][ "Max_Trophies" ] ),
                               "Trophies" => create_cute_hash( player_progression[ char_id ][ "Trophies" ] ) }
                create_graph_box( output_file, [ 0, output_file.cursor ], graph_box_size, graph_data, "Trophies progression", [ true, true ], true, :line, [ 1, 2 ] )

                # Starting a new page for the next brawler
                output_file.start_new_page()
            end

            # Cycling on the players and making comparisons between them
            @player_list.each_with_index do |player, i|
                if player.id != player_id then

                    # Creating a two lines title
                    create_title_box( output_file, [ 0, output_file.cursor ], name_box_size, "#{ref_player.name} vs. #{player.name}" )
                    create_title_box( output_file, [ 0, output_file.cursor + name_box_size[ 1 ] / 3 ],
                                     [ name_box_size[ 0 ], name_box_size[ 1 ] / 2 ],
                                     "#{ref_player.to_pdf_title_string()} vs. #{player.to_pdf_subtitle_string()}" )

                    graph_data = { ref_player.name => players_data_series[ "trophies" ][ ref_player.name ],
                                   player.name => players_data_series[ "trophies" ][ player.name ] }
                    create_graph_box( output_file, [ 0, output_file.cursor ], graph_box_size, graph_data, "Current Trophies", [ false, false ], true )

                    #   puts "Pre graph: #{output_file.cursor}"

                    graph_data = { ref_player.name => players_data_series[ "max_trophies" ][ ref_player.name ],
                                   player.name => players_data_series[ "max_trophies" ][ player.name ] }
                    create_graph_box( output_file, [ 0, output_file.cursor ], graph_box_size, graph_data, "Max trophies", [ true, true ], false, :line, [ 2, 2 ] )

                    # Creating a new page only if there is a new player to show
                    if ( i + 1 ) < @player_list.size then
                        output_file.start_new_page()
                    end
                end
            end

            # Creating a final comparison table
            # Each page will have a maximum of a predefined number of players to
            # compare to
            players_names = @player_list.map{ |player| player.name }.select{ |name| name != ref_player.name }
            ref_player_trophies = players_data_series[ "trophies" ][ ref_player.name ].values + [ ref_player.trophies.trophies ]
            comparison_page_number = 1
            max_comparison_pages = ( ( @player_list.size - 1 ) / ( TABLE_MAX_PLAYERS_NUMBER * 1.0 ) ).ceil
            # Cycling on the subsets of player and create their comparison table
            while not players_names.empty? do

                output_file.start_new_page()

                current_names = players_names.shift( TABLE_MAX_PLAYERS_NUMBER )

                # Creating the data structure for the table for the current
                # players
                data = [ [ "" ] + ORDERED_CHARS.map{ |elem| elem[ 0 ] } + [ "Trophies" ] ]
                data.append( [ ref_player.name ] + ref_player_trophies )
                current_names.each do |player_name|
                    current_player_trophies = players_data_series[ "trophies" ][ player_name ].values +
                                              [ get_player_by_name( player_name ).trophies.trophies ]
                    data.append( [ { :content => player_name, :colspan => 2 } ] + current_player_trophies )
                    data.append( [ "REMOVE" ] + ref_player_trophies.zip( current_player_trophies )
                                                                   .map{ |x,y| sprintf( "[%+d]", x-y ) } )
                end
                data = data.transpose
                # The REMOVE element is just a placeholder in order to transpose the
                # data correctly, since some elements of the first row will cover 2
                # columns
                data[ 0 ].delete( "REMOVE" )
                
                # Title of the page
                create_title_box( output_file, [ 0, PAGE_DIM[ 1 ] - PAGE_MARGIN ], name_box_size, "Final comparison #{comparison_page_number}/#{max_comparison_pages}" )
                # Table
                create_table_box( output_file, [ 0, output_file.cursor ], table_box_size, data )

                # Increasing the page counter
                comparison_page_number += 1
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

    def create_table_box( output_file, starting_point, dimension, data )
        # Deciding the width of the columns based on:
        #  - reference player name
        #  - rest of the player names length halved, because these names
        #  will have two columns for them
        #  - brawlers names
        #  - max character length in the data table which is a 3 digit value
        #  space and another 3 digit value with sign and parenthesis
        #  (i.e. "301 [+102]")
        # The final + 2 is just some space surrounding the name
        max_length = [ data[ 0 ].select{ |name| name.is_a? String }
                                .map{ |name| name.length }.max,
                       data[ 0 ].select{ |name| name.is_a? Hash }
                                .map{ |name| ( name[:content].length / 2.0 ).ceil }.max,
                       CHARS.map{ |brawler, _, _| brawler.length}.max,
                       12 ].max + 2
        font_size = 11
        font_pixel_conversion = 0.75
        lengthoo = max_length * font_size * font_pixel_conversion

        output_file.bounding_box( starting_point, :width => dimension[ 0 ], :height => dimension[ 1 ] ) do

            output_file.font_size( font_size )
            output_file.table( data,
                               :position => :center,
                               :column_widths => [ lengthoo ] * 2 + [ lengthoo / 2 ] * ( data[ 1 ].length - 2 ),
                               :cell_style => { :font => "Courier", :align => :center } ) do |table|

                # Highlighting the first row and column of the table
                table.columns( 0 ).font_style = :bold
                table.rows( 0 ).font_style = :bold

                # Coloring the cells depending on their values
                values = table.cells.columns( 2..-1 ).rows( 1..-1 ).filter{ |cell| cell.content.include? "[" }
                # More trophies
                above = values.filter do |cell|
                    cell.content.match( REGEX_TABLE_CELL_VALUE )[ "sign" ] == "+" and cell.content.match( REGEX_TABLE_CELL_VALUE )[ "value" ] != "0"
                end
                above.text_color = "2EB82E"
                # Fewer trophies
                below = values.filter do |cell|
                    cell.content.match( REGEX_TABLE_CELL_VALUE )[ "sign" ] == "-"
                end
                below.text_color = "FF0000"

                # Highlighting brawlers that are at max rank
                values = table.cells.columns( 1..-1 ).rows( 1..-2 ).filter{ |cell| cell.content.to_i >= BRAWLER_RANKS[ -1 ] }
                values.font_style = :bold

                # Coloring the names of the brawlers based on their rarity
                last_row = 1
                RARITY.each_with_index.map{ |r, i| [ r, CHARS.map{ |char| char[ 1 ] }.count( i ) ] }.each do |rarity, rows|
                    table.rows( last_row..( last_row + rows - 1 ) ).columns( 0 ).background_color = RARITY_COLORS[ rarity ]
                    last_row += rows
                end

                # Borders: adding the borders to what I want
                table.cells.borders = []
                # First line
                table.rows( 0 ).columns( 1..-1 ).borders = [ :bottom, :left ]
                table.rows( 0 ).columns( 1..-1 ).border_width = [ 2, 1 ]
                table.rows( 0 ).columns( 1..-1 ).border_line = [ :solid, :dotted ]
                # First column having dotted on top and solid on the right side
                table.rows( 1..-2 ).columns( 0 ).borders = [ :top, :right ]
                table.rows( 1..-2 ).columns( 0 ).border_width = [ 1, 2 ]
                table.rows( 1..-2 ).columns( 0 ).border_line = [ :dotted, :solid ]
                # Left top corner cell
                table.cells[ 0, 0 ].borders = [ :bottom, :right ]
                table.cells[ 0, 0 ].border_width = 2
                # Adding the left border in the compared players
                ( 2..table.column_length - 1 ).step( 2 ).each do |col|
                    table.columns( col ).rows( 1..-1 ).borders = [ :left ]
                    table.columns( col ).rows( 1..-1 ).border_line = [ :dotted ]
                end
                # Adding the bottom line border
                table.rows( 1..-2 ).columns( 1..-1 ).style{ |cell| cell.borders += [ :top ] and cell.border_line = [ :dotted ] }
                # Last line
                table.rows( table.row_length - 1 ).style{ |cell| cell.borders += [ :top ] and cell.border_line = [ :solid, :dotted ] }
                # Left bottom corner cell
                table.cells[ table.row_length - 1, 0 ].borders = [ :top, :right ]
                table.cells[ table.row_length - 1, 0 ].border_width = [ 1, 2 ]
                table.cells[ table.row_length - 1, 0 ].border_line = [ :solid ]
            end
        end
    end
end
