#!/usr/bin/env ruby
#
# Author: Riccardo Orizio
# Date: Thu 21 Mar 2019 
# Description: Useful constants used in the program
#

# Constants
WEBSITE_LINK = "https://brawland.com"
PLAYER_LINK = "#{WEBSITE_LINK}/player.php?tag="
ID_MINE = "2UR0L90P2"
ID_OTHERS = [ "U29P28CU", "20CQGUQUP", "VQYLLURL", "2U29GP8P0", "2R20P2VC", "R0YLYCVL" ]
IDS = [ ID_MINE, ID_OTHERS ].flatten
DIR_WEBPAGES = "./Webpages"

# Regex
REGEX_TROPHIES = /rank:\s*([a-zA-Z\s]*)\s*(\d+)\s*\/\s*(\d+)/
REGEX_EXPERIENCE = /level:\s*(\d+)[^0-9]*(\d+)[^0-9]*\d+\s*(\d+)[^0-9]*(\d+)/
REGEX_VICTORIES = /3v3[^0-9]*(\d+)[^0-9]*(\d+)[^0-9]*(\d+)/
REGEX_BRAWLER = /([^0-9]*)\s+(\d+)\s*(\d+)[\s\/]*(\d+)/
