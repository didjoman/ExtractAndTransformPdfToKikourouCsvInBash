#!/bin/bash

# This program is used to get the result of the course "Ascension du col de Braus",
# It transforms the pdf to a txt file and parse the txt file to generate a csv file for the website Kikourou.

# #################
# ### CONSTANTS ###
# #################

# Urls used 
PDF_URL="https://jsdcourse.files.wordpress.com/2016/08/col-de-braus-2016-course.pdf"
FIRSTNAMES_URL="https://www.data.gouv.fr/s/resources/liste-de-prenoms/20141127-154433/Prenoms.csv"

# Local files
PDF_FILE="col-de-braus-2016-course.pdf"
TXT_FILE="col-de-braus-2016-course.txt"
FIRSTNAMES_FILE="Prenoms.csv"
OUTPUT_FILE="output.csv"

# #################
# ### FUNCTIONS ###
# #################

function log_error {
    echo "$1" >&2
}

function log_wrong_numer_parameters {
    local function_name="$1"
    local nb_params="$2"
    log_error "[$function_name] Wrong number of parameters (awaited $nb_params)"
}

function ask_gender {
    # Get params
    if [ $# -lt 2 ]; then
	log_wrong_numer_parameters ask_gender 2
	return 1
    fi

    local firstname="$1"
    local line="$2"

    # Ask gender to the user :
    local gender=""
    while [ "$gender" != m -a "$gender" != f ] ; do  
	read -p "Problem with line : ${line}
 What is the gender of $firstname ? [m/f]" gender
    done
    
    echo "$gender"
}

function find_gender {
    # Get params
    if [ $# -lt 2 ]; then
	log_wrong_numer_parameters find_gender 2
	return 1
    fi

    local firstname="$1"
    local line="$2"
    
    # Guess from file
    local gender=$(sed -n "s/^${firstname}\;\([mf]\)[,;].*/\1/p" "$FIRSTNAMES_FILE") # Note : if the firstname can be male or female, we take man (sorry ...)

    # Ask missing names to the user
    if [ -z "$gender" ]; then
	gender=$(ask_gender "$firstname" "$line")
    fi
    
    echo "$gender"
}

function get_file {
    # Get params
    if [ $# -lt 2 ]; then
	log_wrong_numer_parameters get_file 2
	return 1
    fi

    local url="$1"
    local output="$2"
    echo "$url"
    rm "$output" 1>/dev/null 2>&1
    curl "$url" --create-dirs -o "$output"
}

# #################
# ##### MAIN ######
# #################

# Get the result :
get_file "$PDF_URL" "$PDF_FILE"

# Transform pdf in text (columns are separated by multiple spaces)
pdftotext "$PDF_FILE" -layout "$TXT_FILE"

# 1) Replace Strange ^L chars
# 2) Remove useless lines at the end and beginning
# 3) Remove spaces in head of lines
# 4) Remove the precedently unremoved spaces after the chrono
# 5) Select only the interesting colunms place, time, category, club
# 6) Remove club "INDIVIDUEL" (= absence of club) 
# 7) Remove space between firstname and lastname
# 8) Remove empty lines
lines=$(cat -v "$TXT_FILE" | sed "s/\^L//g" | tail -n +4 |sed -n "s/\(^\ *\)//p" | sed -n "s/\ \{2,100\}/\;/gp" | sed "s/\(.*:[0-9]\{2\}\)\ \(.*\)/\1\;\2/" | cut -d \; -f 1,2,4,5,6,8 | sed "s/INDIVIDUEL//" | sed "s/\(.*[A-Z]*\)\ \([A-Z]*\;.*\;.*\;.*\)/\1;\2/")

# Get FirstNames file
get_file "$FIRSTNAMES_URL" "$FIRSTNAMES_FILE"

# Now, guess absent info (people's gender).
# To do so, I use a government csv dictionnary which associates names with genders.

firstLine='class;temps;nom;cat;sexe;club'
newLines="$firstLine"

IFS=$'\n'
for line in $lines; do
    # Extract firstname & find gender
    firstname=$(echo "$line" | cut -d \; -f 4 | tr [:upper:] [:lower:])
    gender=$(find_gender "$firstname" "$line")
    # Complete the line with the gender found
    line=$(echo "$line" | sed -n "s/\(.*\;.*\;.*\;.*\;\)\(.*\)/\1${gender}\;\2/p")
    newLines="${newLines}"$'\n'"$line"
done
IFS=" "

# Write in file :
echo "$newLines" | sed '/^\s*$/d' > "$OUTPUT_FILE"



