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
# TODO: Problem with Chinese name formatting when creating the pdf. It is an
# open problem with Prawn gem.
ID_OTHERS = [ "U29P28CU",
              "20CQGUQUP",
              "VQYLLURL",
              "2U29GP8P0",
              "8LY9VP2UV",
              "PQJQPG2G",
              "8YCYURYL",
              "J8PRC802",
              "2R20P2VC",
              "2YV9P0JV8",
              "2L8LLUJJV",
              "8CJ090LV",
              "2PJ09CGYR",
              "LL0J2YG",
              "R0YLYCVL",
              "28LUY98",
              "2L892GP" ]

IDS = [ ID_MINE, ID_OTHERS ].flatten
DIR_WEBPAGES = "./Webpages"

# Regex
REGEX_TROPHIES = /rank:\s*([a-zA-Z\s]*)\s*(\d+)\s*\/\s*(\d+)/
REGEX_EXPERIENCE = /level:\s*(\d+)[^0-9]*(\d+)[^0-9]*\d+\s*(\d+)[^0-9]*(\d+)/
REGEX_VICTORIES = /3v3[^0-9]*(\d+)[^0-9]*(\d+)[^0-9]*(\d+)/
REGEX_BRAWLER = /([^0-9]*)\s+(\d+)\s*(\d+)[\s\/]*(\d+)/
REGEX_FILE_LINE_STATS = /([^\t]*)\t([^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*)\t((([0-9]+\t[0-9]+\t[0-9]+)\t)*)/
REGEX_FILE_LINE_CHAR_STATS = /((?<rank>[0-9]+)\t(?<trophies>[0-9]+)\t(?<max>[0-9]+))\t/
REGEX_DATE_ONLY = /([0-9\/]+)/


# Rarities and list of known brawlers
RARITY = [ "Common", "Rare", "Super Rare", "Epic", "Mythic", "Legendary" ]
#   Rarity colors if they would ever be needed
#   RARITY = [ [ "Common", "94D7F4" ],
#              [ "Rare", "2EDD16" ],
#              [ "Super Rare", "008FFA" ],
#              [ "Epic", "B116ED" ],
#              [ "Mythic", "D6001A" ],
#              [ "Legendary" "FFF11E" ] ]
CHARS = [ [ "Shelly", 0, 0 ],
          [ "Nita", 0, 8 ],
          [ "Colt", 0, 1 ],
          [ "Bull", 0, 2 ],
          [ "Jessie", 0, 7 ],
          [ "Brock", 0, 3 ],
          [ "Dynamike", 0, 9 ],
          [ "Bo", 0, 14 ],
          [ "El Primo", 1, 10 ],
          [ "Barley", 1, 6 ],
          [ "Poco", 1, 13 ],
          [ "Rico", 2, 4 ],
          [ "Darryl", 2, 18 ],
          [ "Penny", 2, 19 ],
          [ "Carl", 2, 25 ],
          [ "Piper", 3, 15 ],
          [ "Pam", 3, 16 ],
          [ "Frank", 3, 20 ],
          [ "Mortis", 4, 11 ],
          [ "Tara", 4, 17 ],
          [ "Gene", 4, 21 ],
          [ "Spike", 5, 5 ],
          [ "Crow", 5, 12 ],
          [ "Leon", 5, 23 ],
          [ "Rosa", 1, 24 ] ]
BRAWLSTATS_ID_CONSTANT = 16000000

# Player ranks divided by trophies
PLAYER_RANKS = [ [ 0, "Unranked" ],
                 [ 500, "Wood I" ],
                 [ 650, "Wood II" ],
                 [ 800, "Wood III" ],
                 [ 1000, "Bronze I" ],
                 [ 1300, "Bronze II" ],
                 [ 1600, "Bronze III" ],
                 [ 2000, "Silver I" ],
                 [ 2300, "Silver II" ],
                 [ 2600, "Silver III" ],
                 [ 3000, "Gold I" ],
                 [ 3300, "Gold II" ],
                 [ 3600, "Gold III" ],
                 [ 4000, "Diamond I" ],
                 [ 4500, "Diamond II" ],
                 [ 5000, "Diamond III" ],
                 [ 5500, "Diamond IV" ],
                 [ 6000, "Crystal I" ],
                 [ 6500, "Crystal II" ],
                 [ 7000, "Crystal III" ],
                 [ 7500, "Crystal IV" ],
                 [ 8000, "Master I" ],
                 [ 8500, "Master II" ],
                 [ 9000, "Master III" ],
                 [ 9500, "Master IV" ],
                 [ 10000, "All-Star I" ],
                 [ 11000, "All-Star II" ],
                 [ 12000, "All-Star III" ],
                 [ 13000, "All-Star IV" ],
                 [ 14000, "All-Star V" ] ]

# Export file constants
EXPORT_FILE_DIR = "./Stats"
EXPORT_FILE_NAME = "full_exported_stats"
EXPORT_FILE_EXT = ".csv"
LINES_TO_READ = 15

IMAGES_DIR = "./Images"
PAGE_DIM = [ 1000, 700 ]
PAGE_MARGIN = 36
REAL_PAGE_DIM = [ PAGE_DIM[ 0 ] - 2 * PAGE_MARGIN, PAGE_DIM[ 1 ] - 2 * PAGE_MARGIN ]
RATE_BRAWLER_INFO = 0.5

# Redefinition of the constant is annoying
# Telling the interpreter to ignore these warnings
warn_level = $VERBOSE
$VERBOSE = nil
EXPORT_FILE_HEADER_LINE = "Name\t#\tRank\tTrophies\tMax Trophies\t3v3\t2v2\t1v1\t"
CHARS.each do |char|
    EXPORT_FILE_HEADER_LINE += "#{char[ 0 ]}'s Rank\t#{char[ 0 ]}'s Trophies\t#{char[ 0 ]}'s Max Trophies\t"
end
EXPORT_FILE_HEADER_LINE += "\n"
$VERBOSE = warn_level

PDF_FILE_DIR = "./Comparisons"
PDF_FILE_EXT = ".comparison.pdf"
