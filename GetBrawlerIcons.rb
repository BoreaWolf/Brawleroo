#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Fri 26 Apr 2019
# Description: Saving locally each brawler icon
#

require "./Constants.rb"
require "open-uri"

def get_brawler_icons()
    CHARS.each do |char_name, _, _|
        print "Saving icon of #{char_name}."
        dev_name = char_name.downcase
        dev_name = "jess" if char_name == "Jessie"
        dev_name = "mike" if char_name == "Dynamike"
        dev_name = "primo" if char_name == "El Primo"
        dev_name = "rick" if char_name == "Rico"
        dev_name = "barrelbot" if char_name == "Darryl"
        dev_name = "mj" if char_name == "Pam"
        dev_name = "taro" if char_name == "Tara"
        open( "#{HERO_ICON_LINK}#{dev_name}#{HERO_ICON_EXT}" ) do |image_link|
            File.open( "#{IMAGES_DIR}/hero_#{char_name.downcase}#{HERO_ICON_EXT}", "w" ) do |image|
                image.puts( image_link.read() )
            end
        end
        puts "...DONE o(^▽^)o"
    end
end

