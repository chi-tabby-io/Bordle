#!/bin/bash 

# ============================ GLOBAL VAR DEFINITIONS ========================

#TODO: perhaps search for the word file on Linux systems, else download the word file from a link
declare DICT_DIR="./dict"
declare BASE_WORD_FILE="$DICT_DIR/words" 
declare FIVE_WORD_FILE="$DICT_DIR/words_five"
declare USER_DATA_DIR="./user_data" 
declare GAME_DATA_FILE="./$USER_DATA_DIR/wordle_game_data"

declare DATE=$( date +%s ) 

declare WIDTH=$( tput cols )
declare HEIGHT=$( tput lines )

declare -a BORDL_TEXT
BORDL_TEXT+=( "▄▄███▄▄·██████╗  ██████╗ ██████╗ ██████╗ ██╗     " ) 
BORDL_TEXT+=( "██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██║     " ) 
BORDL_TEXT+=( "███████╗██████╔╝██║   ██║██████╔╝██║  ██║██║     " ) 
BORDL_TEXT+=( "╚════██║██╔══██╗██║   ██║██╔══██╗██║  ██║██║     " ) 
BORDL_TEXT+=( "███████║██████╔╝╚██████╔╝██║  ██║██████╔╝███████╗" )
BORDL_TEXT+=( "╚═▀▀▀══╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝" )

declare GAME_RULES_STR="Game Rules:"
declare GAME_RULES_LEN=${#GAME_RULES_STR}

declare INSTRUCTIONS
INSTRUCTIONS+=( "1. I have come up with a 5 letter word. You must guess it correctly in 6 attempts.        " )
INSTRUCTIONS+=( "2. After each attempt, I will give you feedback on your guess, according to the following:" )
INSTRUCTIONS+=( "   a. If a letter is in the word but in the wrong position, I will mark it orange.        " )
INSTRUCTIONS+=( "   b. If a letter is in the word and in the correct position, I will mark it green.       " )
INSTRUCTIONS+=( "   c. If a letter is not in the word, I will not mark it at all.                          " )
INSTRUCTIONS+=( "3. Repeats are allowed.                                                                   " )

declare GAME_BOARD_CELL_WIDTH=10
declare GAME_BOARD_CELL_HEIGHT=4
declare GAME_BOARD_NUM_CELL_WIDE=5
declare GAME_BOARD_NUM_CELL_HIGH=6
declare GAME_BOARD_N_CHAR_WIDTH=$(( GAME_BOARD_CELL_WIDTH * GAME_BOARD_NUM_CELL_WIDE + GAME_BOARD_NUM_CELL_WIDE + 1 ))	
declare GAME_BOARD_N_CHAR_HEIGHT=$(( GAME_BOARD_CELL_HEIGHT * GAME_BOARD_NUM_CELL_HIGH + GAME_BOARD_NUM_CELL_HIGH + 1 )) 

declare KEY_BOARD_CELL_WIDTH=3
declare KEY_BOARD_CELL_HEIGHT=1
declare KEY_BOARD_NUM_CELL_WIDE=( 10 9 7 )
declare KEY_BOARD_NUM_CELL_HIGH=3
declare KEY_BOARD_N_CHAR_WIDTH=$(( KEY_BOARD_CELL_WIDTH * ${KEY_BOARD_NUM_CELL_WIDE[0]} + ${KEY_BOARD_NUM_CELL_WIDE[0]} + 1 ))
declare KEY_BOARD_N_CHAR_HEIGHT=$(( KEY_BOARD_CELL_HEIGHT * KEY_BOARD_NUM_CELL_HIGH + KEY_BOARD_NUM_CELL_HIGH + 1 ))

declare QWERTY_KEY_BOARD=( "qwertyuiop" "asdfghjkl" "zxcvbnm" )

# ========================= DRAWING FUNCTIONS ===============================

# $1 == cursor_x $2 == cursor_y
draw_wordle_text() {
	cursor_x=$1
	cursor_y=$2
	
	tput cup $cursor_x $cursor_y
	for row in "${BORDL_TEXT[@]}"
	do
		echo "$row"
		(( cursor_x++ ))	
		tput cup $cursor_x $cursor_y
	done
}

draw_welcome_screen() {
	clear
	welcome_str="Welcome to:"

	local cursor_x=$(( ( HEIGHT / 6 ) -  6 ))
	local cursor_y=$(( ( WIDTH / 2 ) - ( ${#welcome_str} / 2  ) ))
	tput cup $cursor_x $cursor_y
	echo $welcome_str

	(( cursor_x += 3 ))
	(( cursor_y = ( WIDTH / 2 ) - ( ${#BORDL_TEXT[1]} / 2 ) ))	
	draw_wordle_text $cursor_x $cursor_y
	
	(( cursor_x += 2 ))	
	(( cursor_y = ( WIDTH / 2 ) - ( GAME_RULES_LEN / 2 ) ))
	draw_instructions $cursor_x $cursor_y 

	user_prompt="[INFO] To continue, press any key"
	(( cursor_x += 2 ))	
	(( cursor_y = ( WIDTH / 2 ) - ( ${#user_prompt} / 2 ) ))
	tput cup $cursor_x $cursor_y
	read -p "$user_prompt" -rsn1 user_input
	clear
}

# $1 == cursor_x $2 == cursor_y 
draw_instructions() {
	cursor_x=$1
	cursor_y=$2

	tput cup $cursor_x $cursor_y 
	echo $GAME_RULES_STR
	
	(( cursor_x += 2 ))
	# WARNING: depending on screen size, #INSTRUCTIONS[1] > $WIDTH is possible,
	# Resulting in a tput not being able to place the cursor. need to find a way
	# to wrap text	
	(( cursor_y = ( WIDTH / 2 ) - ( ${#INSTRUCTIONS[1]} / 2 ) )) 
	 tput cup $cursor_x $cursor_y

	for line in "${INSTRUCTIONS[@]}"
	do
		echo "$line"
		(( cursor_x++ ))
		tput cup $cursor_x $cursor_y
	done

	gl_str="Good luck!"
	(( cursor_x += 2 ))
	(( cursor_y = ( WIDTH / 2 ) - ( ${#gl_str} / 2 ) ))
	tput cup $cursor_x $cursor_y	
	echo "$gl_str"	
}

# $1 == cursor_x $2 == cursor_y
draw_empty_table() {
	cursor_x=$1
	init_cursor_y=$2	
	cursor_y=$init_cursor_y

	tput cup $cursor_x $cursor_y	
	for (( i=1; i<=$GAME_BOARD_N_CHAR_HEIGHT; i++ ))	
	do
		if [ $(( i % ( GAME_BOARD_CELL_HEIGHT + 1 ) )) -eq 1 ]
		then	
			for (( j=1; j<=$GAME_BOARD_N_CHAR_WIDTH; j++ )) 
			do
				[ $(( j % ( GAME_BOARD_CELL_WIDTH + 1 ) )) -eq 1 ] && echo -n "+" || echo -n "-" 
			done
		else
			for (( j=1; j<=$GAME_BOARD_N_CHAR_WIDTH; j++ )) 
			do
				[ $(( j % ( GAME_BOARD_CELL_WIDTH + 1 ) )) -eq 1 ] && echo -n "|" || echo -n " " 
			done
		fi
		(( cursor_x++ ))
		(( cursor_y = init_cursor_y ))	
		tput cup $cursor_x $cursor_y	
	done
}

# $1 == cursor_x $2 == cursor_y
draw_keyboard() {
	cursor_x=$1
	(( cursor_x++ ))
	init_cursor_y=$(( ( WIDTH / 2 ) - ( KEY_BOARD_N_CHAR_WIDTH / 2 ) ))
	cursor_y=$init_cursor_y
	tput cup $cursor_x $cursor_y

	key_board_row_index=0

	for (( i=1; i<=$KEY_BOARD_N_CHAR_HEIGHT; i++ ))	
	do
		
		if [ $(( i % ( KEY_BOARD_CELL_HEIGHT + 1 ) )) -eq 1 ]
		then	
			for (( j=1; j<=$KEY_BOARD_N_CHAR_WIDTH; j++ )) 
			do
				[ $(( j % ( KEY_BOARD_CELL_WIDTH + 1 ) )) -eq 1 ] && echo -n "+" || echo -n "-" 
			done
		else
			lett_index=0	
			for (( j=1; j<=$KEY_BOARD_N_CHAR_WIDTH; j++ )) 
			do
				if [ $(( j % ( KEY_BOARD_CELL_WIDTH + 1 ) )) -eq 1 ]
				then
					echo -n "|"
				else
					tput setaf 0	
					tput setab 6	
					char_row="${QWERTY_KEY_BOARD[$key_board_row_index]}"
					if [ $(( ( j + 1 ) % ( KEY_BOARD_CELL_WIDTH + 1 ) )) -eq 0 ] && [ $lett_index -lt ${#char_row} ]
					then
						echo -n ${char_row:lett_index:1}
						(( lett_index++ ))
					else
						echo -n " " 
					fi
					tput setaf 9	
					tput setab 9
				fi
			done
			(( key_board_row_index++ ))
		fi
		(( cursor_x++ ))
		(( cursor_y = init_cursor_y ))	
		tput cup $cursor_x $cursor_y	
	done

}

draw_init_screen() {
	clear	
	local cursor_x=3
	local cursor_y
	(( cursor_y = WIDTH / 2 - ( ${#BORDL_TEXT[1]} / 2 ) ))	
	draw_wordle_text $cursor_x $cursor_y	
	
	(( cursor_x += 2 ))
	(( cursor_y = ( WIDTH / 2 ) - ( GAME_BOARD_N_CHAR_WIDTH / 2 ) ))
	draw_empty_table $cursor_x $cursor_y

	(( cursor_x += 2 ))
	(( cursor_y = ( WIDTH / 2 ) - ( GAME_BOARD_N_CHAR_WIDTH / 2 ) ))
	draw_keyboard $cursor_x $cursor_y
}

# $1 == input $2 == char_stack $3 == guesses $4 == color_array
redraw_board() {
	local input=$1	
	local -n _char_stack=$2
	local -n _guesses=$3
	local -n _color_array=$4
	local cursor_x=$(( 3 + ${#BORDL_TEXT[@]} + 2 + 1 ))
	local cursor_y=$(( ( WIDTH / 2 ) - ( GAME_BOARD_N_CHAR_WIDTH / 2 ) + 1 ))
	
	ROW_NUM=$(( ${#_guesses[@]} % 6 ))
	COL_NUM=$(( ( ${#_char_stack[@]} - 1 ) % 5 ))
	(( cursor_x += ROW_NUM * ( GAME_BOARD_CELL_HEIGHT + 1 ) ))
	(( cursor_y += COL_NUM * ( GAME_BOARD_CELL_WIDTH + 1 ) ))

	case $input in
		[a-z]) # user input letter
			tput cup $cursor_x $cursor_y
			echo $input 
			;;
		"\n") # user wants to validate guess
			color_board_cells _char_stack _color_array $ROW_NUM
			;;
		$'\177') # user wants to erase last letter
			unset _char_stack[-1] 
			tput cup $cursor_x $cursor_y
			echo " "
			;;
		*)
			echo "anything"	
			return	
			;;	
	esac
}

# $1 == char_stack $2 == color_array $3 == ROW_NUM
color_board_cells() {
	local -n __char_stack=$1	
	local -n __color_array=$2
	local ROW_NUM=$3
	local init_cursor_x=$(( 3 + ${#BORDL_TEXT[@]} + 2 + 1 + ROW_NUM * ( GAME_BOARD_CELL_HEIGHT + 1 ) ))
	local init_cursor_y=$(( ( WIDTH / 2 ) - ( GAME_BOARD_N_CHAR_WIDTH / 2 ) + 1 ))
	local cursor_x=$init_cursor_x
	local cursor_y=$init_cursor_y

	for (( i=0;i<$GAME_BOARD_NUM_CELL_WIDE;i++ ))
	do
		(( cursor_x = $init_cursor_x ))	
		(( cursor_y = $init_cursor_y + $i * ( $GAME_BOARD_CELL_WIDTH + 1 ) ))
		# set background color, foreground color
		tput setab ${__color_array[$i]}	
		for (( j=0;j<$GAME_BOARD_CELL_WIDTH;j++ ))
		do
			(( cursor_y += $j ))
			for (( k=0;k<$GAME_BOARD_CELL_HEIGHT;k++ ))
			do
				(( cursor_x += $k ))
				tput cup $cursor_x $cursor_y
				[ $j -eq 0 ] && [ $k -eq 0 ] && echo "${__char_stack[$i]}" || echo " "
				(( cursor_x = $init_cursor_x))	
			done
			(( cursor_y = $init_cursor_y + $i * ( $GAME_BOARD_CELL_WIDTH + 1 ) ))
			sleep 0.03 
		done
	done
 	tput sgr0
}

# $1 == color_map
color_keyboard_cells() {
	local -n _color_map=$1	
	local init_cursor_x=$(( 3 + ${#BORDL_TEXT[@]} + 2 + 1 + GAME_BOARD_NUM_CELL_HIGH * ( GAME_BOARD_CELL_HEIGHT + 1 ) + 4 ))
	local init_cursor_y=$(( ( WIDTH / 2 ) - ( KEY_BOARD_N_CHAR_WIDTH / 2 ) + 2 ))
	local cursor_x=$init_cursor_x
	local cursor_y
	for (( i=0;i<${#QWERTY_KEY_BOARD[@]};i++ ))
	do
		cursor_y=$init_cursor_y
		char_row=${QWERTY_KEY_BOARD[$i]}
		
		for (( j=0;j<${#char_row};j++))
		do
			lett=${char_row:j:1}
			for key in "${!_color_map[@]}"
			do
				if [ "$lett" = "$key" ] # an alternative is to get just keys array and check with in_arr
				then
					# do not recommend this kind of coding to anyone	
					(( cursor_y-- ))	
					tput cup $cursor_x $cursor_y
					tput setaf 7
					tput setab ${_color_map[$key]}
					echo -n " "
					(( cursor_y++ ))	
					tput cup $cursor_x $cursor_y
					echo -n "$lett"	
					(( cursor_y++ ))	
					tput cup $cursor_x $cursor_y
					echo -n " "
					(( cursor_y-- ))
					break	
				fi
			done	
			(( cursor_y += KEY_BOARD_CELL_WIDTH + 1 ))
		done
		(( cursor_x += KEY_BOARD_CELL_HEIGHT + 1 ))
	done	
	tput sgr0	

}

# $1 == status_msg
draw_game_status() {
	status_msg=$1
	local init_cursor_x=$(( 3 + ${#BORDL_TEXT[@]} + 2 + 1 + GAME_BOARD_N_CHAR_HEIGHT ))
	local init_cursor_y=0 
	local cursor_x=$init_cursor_x
	local cursor_y=$init_cursor_y 
	
	tput cup $cursor_x $cursor_y
	tput el	

	(( cursor_y = ( WIDTH  / 2 ) - ${#status_msg} / 2 ))
	tput cup $cursor_x $cursor_y
	echo "$status_msg"
}

draw_exit_status() {
	#TODO: replace the text drawn to screen	
	#local init_cursor_x=$(( 3 + ${#BORDL_TEXT[@]} + 2 + 1 + GAME_BOARD_N_CHAR_HEIGHT + 2 ))
	#local init_cursor_y=0 
	#local cursor_x=$init_cursor_x
	#local cursor_y=$init_cursor_y 
	#
	#tput cup $cursor_x $cursor_y
	
	read -p "Press any key to exit" -rsn1 user_input
	(( cursor_x++ ))	
	tput cup $cursor_x $cursor_y	
	echo "Exiting..."
	sleep 0.75
	clear
}

draw_user_stats() {
	clear
	
	max() {
		local -n _guess_list=$1
		maximum=${_guess_list[0]}
		for num_guess in "${_guess_list[@]}"
		do
			[ $num_guess -gt $maximum ] && maximum=$num_guess
		done
		printf ${maximum}	
	}	
	
	local last_num_guess=$( cat $GAME_DATA_FILE | grep "^last_num_guess" | awk '{print $3}' )	
	local -a guess_list	
	local DIVISIONS=4
	local guess_dist_str="GUESS DISTRIBUTION"
	local init_cursor_x=0
	local init_cursor_y=$(( (WIDTH / 2 ) - ( ${#guess_dist_str} / 2 ) ))	

	local cursor_x=$init_cursor_x
	local cursor_y=$init_cursor_y

	local games_won=$( cat $GAME_DATA_FILE | grep "^games_won" | awk '{print $3}' )

	games_won=$( cat $GAME_DATA_FILE | grep "games_won" | awk '{print $3}' )	
	if [ $games_won -eq 0 ]
	then
		guess_list=( 0 0 0 0 0 0 )
	else		
		for i in {1..6}	
		do
			guess_list+=( $( cat $GAME_DATA_FILE | grep "games_in_$i" | awk '{print $3}' ) )	
		done
	fi
	
	local max_num_guess=$( max guess_list )	
	local min_text_width=$(( ${#max_num_guess} + 3 ))	
	
	tput cup $cursor_x $cursor_y 
	printf "$guess_dist_str" 
	(( cursor_x += 2 ))
	
	for i in {0..5}
	do
		(( cursor_x += 2 ))
		(( cursor_y = WIDTH / DIVISIONS ))
		
		space_to_right=$(( WIDTH - cursor_y ))	
		num_guess_i=${guess_list[$i]}  	
		
		tput cup $cursor_x $cursor_y 
		printf "%*s" $min_text_width "$(( i + 1 )) | "
	
		(( cursor_y += min_text_width ))	
		tput cup $cursor_x $cursor_y 
		[ $last_num_guess -eq $(( i + 1 )) ] && tput setab 2 || tput setab 7	
		if [ $games_won -eq 0 ]
		then	
			echo -n " "	
		else
			num_bars=$(( num_guess_i * space_to_right * ( DIVISIONS - 1 ) / ( games_won * DIVISIONS ) ))	
			for (( j=0;j<=$num_bars;j++))
			do
				echo -n " "
			done
		fi			
		tput setab 9
	done
	
	(( cursor_x += 4 ))
	tput cup $cursor_x $cursor_y 
	# TODO: continue to develop statistics page
}

# ====================== UTILITY FUNCTIONS ==============================

# $1 == guess $2 == guesses 
validate_guess() {
	local -n _guesses=$2	
	local status_msg
		
	if ! grep -Fxq "$1" $FIVE_WORD_FILE
	then
		status_msg="'$1' was not found in word list!"
		exit_status=1	
	elif [[ ${_guesses[*]} =~ (^|[[:space:]])"$1"($|[[:space:]]) ]] 
	then
		status_msg="'$1' already guessed!"
		exit_status=1
	else
		exit_status=0	
	fi
	
	[ $exit_status -eq 1 ] && draw_game_status "$status_msg"	
	return $exit_status	
}

# $1 == $guess $2 == $seen
add_to_seen() {
	guess=$1
	seen=$1
	local seen_bool
	
	for (( i=0;i<${#guess};i++ ))
	do
		j=0
		while true
		do
			[ $j -eq ${#seen[@]} ] && seen_bool=0 && break
			[ "${guess:i:1}" = "${seen[$j]}" ] && seen_bool=1 && break
			(( j++ ))	
		done
		[ $seen_bool -eq 0 ] && seen+=( "${guess:i:1}" )	
	done	
}

# $1 == target $2 == container
in_arr() {
	local target=$1
	local -n _array=$2	
	if [ ${#_array[@]} -ne 0 ]
	then	
		for _element in "${_array[@]}"
		do	
			[ "$target" = "$_element" ] && return
		done
	fi
	false
}

#TODO: typechecking on input: either array or map
# $1 == arr $2 == ordered_set_arr
to_ordered_set() {
	local -n _arr=$1
	local -n _ordered_set_arr=$2
	
	for _elem in "${_arr[@]}"
	do
		if ! in_arr $_elem _ordered_set_arr 
		then
			_ordered_set_arr+=( $_elem )
		fi
	done
} 

# $1 == guess $2 == num_guess
win_or_lose() {
	local status_msg	
	local exit_status	
	if [ $1 = $WORD ]
	then
		status_msg="You won! Congrats 😎"
		exit_status=0	
	elif [ $2 -eq 6 ]
	then
		status_msg="You lost 😭😭😭 the word was $WORD"	
		exit_status=0	
	else
		exit_status=1	
	fi
	draw_game_status "$status_msg" && return $exit_status
}

# $1 == guess $2 == num_guess
won() {
	[[ $1 == $WORD && ! $2 > 6 ]] && return
	false
}

# tput colors to use:
# green == 2
# orange == 3
# default == 9
# $1 == guess $2 == word $3 == color_map $4 == color_array
get_color_mappings() { 
	guess=$1
	word=$2
	local -n _color_map=$3
	local -n _color_array=$4
	unset _color_map[0] #when passing by name ref, initial key val pair of 0, none (?) is made	
	unset _color_array[0]
	local color_value=9	
	
	# echo [DEBUG] Word is \'$word\'
	for (( i=0;i<${#guess};i++ ))
	do
		guess_i=${guess:i:1}
		if [[ $word =~ "$guess_i" ]]
		then
			match=0
			for (( j=0;j<${#word};j++ ))
			do
				if [ $guess_i = ${word:j:1} ] && [ $i -eq $j ]
				then
					match=1
					break
				fi
			done
			if [ $match -eq 1 ]
			then
				color_value=2
			else	
				color_value=3	
			fi
		fi

		#TODO: needs further debugging	
		if [ "${_color_map[$guess_i]}" != "" ]
		then
			[ $color_value -lt ${_color_map[$guess_i]} ] && _color_map[$guess_i]=$color_value
		else
			_color_map[$guess_i]=$color_value
		fi	
		_color_array[$i]=$color_value
		(( color_value=9 ))	
	done
}

# ========================== GAME DATA MANIPULATION ============================

init_game_data() {
	if ! [ -d $USER_DATA_DIR ] && ! [ -s $GAME_DATA_FILE ] 
	then
		mkdir $USER_DATA_DIR	
		touch "$GAME_DATA_FILE"
		printf "date : 0\n" >> $GAME_DATA_FILE
		printf "games_played : 0\n" >> $GAME_DATA_FILE	
		printf "games_won : 0\n" >> $GAME_DATA_FILE 
		for row in {1..6}
		do
			printf "games_in_$row : 0\n" >> $GAME_DATA_FILE
		done
		printf "last_num_guess : 0" >> $GAME_DATA_FILE
	fi	
	
	if ! [ -d $DICT_DIR ] 
	then
		mkdir $DICT_DIR
		# wget base word file, change name to base word file if nec	
		touch "$BASE_WORD_FILE"
		touch "$FIVE_WORD_FILE"	
		wget -q 'https://users.cs.duke.edu/~ola/ap/linuxwords'	
		cat linuxwords > "$BASE_WORD_FILE"	
		egrep "^[a-z]{5}\$" "$BASE_WORD_FILE" > "$FIVE_WORD_FILE"
		rm linuxwords
	fi
}

reset_game_data() {
	sed -i "s/date : [0-9]*/date : 0/" $GAME_DATA_FILE 
	sed -i "s/games_played : [0-9]*/games_played : 0/" $GAME_DATA_FILE 
	sed -i "s/games_won : [0-9]*/games_won : 0/" $GAME_DATA_FILE	
	for i in {1..6}
	do
		sed -i "s/games_in_$i : [0-9]*/games_in_$i : 0/" $GAME_DATA_FILE 
	done
	sed -i "s/last_num_guess : [1-6]/last_num_guess : 0" $GAME_DATA_FILE
}

# $1 == guess $2 == date_last_played $3 == num_guess  
serialize_data() {
	date_last_played_info=$( cat $GAME_DATA_FILE | grep "^date" )
	sed -i "s/$date_last_played_info/date : $2/" $GAME_DATA_FILE 
	if [ $1 == $WORD ] && ! [ $3 > 6 ] 
	then
		this_game_freq_info=$( cat $GAME_DATA_FILE | grep "^games_in_$3" )
		this_game_freq=$( echo $this_game_freq_info | awk '{print $3}' )
		(( this_game_freq++ ))
		sed -i "s/$this_game_freq_info/games_in_$3 : $this_game_freq/g" $GAME_DATA_FILE	
		games_won_info=$( cat $GAME_DATA_FILE | grep "^games_won" )
		games_won=$( echo $games_won_info | awk '{print $3}' )
		(( games_won++ ))
		sed -i "s/$games_won_info/games_won : $games_won/" $GAME_DATA_FILE 
	fi
	games_played_info=$( cat $GAME_DATA_FILE | grep "^games_played" )
	games_played=$( echo $games_played_info | awk '{print $3}' )
	(( games_played++ ))
	sed -i "s/$games_played_info/games_played : $games_played/" $GAME_DATA_FILE
	last_num_guess_info=$( cat $GAME_DATA_FILE | grep "^last_num_guess" )	
	sed -i "s/$last_num_guess_info/last_num_guess : $3/" $GAME_DATA_FILE
}


played_today() {

	date_last_played=$( cat $GAME_DATA_FILE  | grep "^date" | awk '{print $3}' ) 
	TIME_DIFF=$(( $DATE - $date_last_played ))
	OFFSET=$( date +%::z | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
	TIME_LEFT_TODAY=$(( 86400 - (( $date_last_played + $OFFSET ) % 86400 ) ))
	[ $TIME_DIFF -lt $TIME_LEFT_TODAY ] && return 
	false
}

# processing command line arguments...

TEMP=$( getopt -o hfs --long help,forget-date,stats -n "$0" -- "$@" )

if [ $? != 0 ] 
then
	echo "To get help, use flags -h or --help"
	echo "Terminating..." >&2 
   	exit 1 
fi

eval set -- "$TEMP"

declare forget_date=false

while true
do
	case "$1" in
		-h | --help)
			printf "\nusage: ./bordle.sh [-h | --help] [-f | --forget-date] [-s | --stats]\n\n"
			printf "\t-h, --help\t\tdisplay this message\n"
			printf "\t-f, --forget-date\twhen included, allows user to play more than once a day\n"	
			printf "\t-s, --stats\t\tdisplays the user stats\n\n"	
			exit 0
			break	
			;;	
		-f | --forget-date) forget_date=true 
			shift
			;;
		-s | --stats)
			draw_user_stats 
			read -p "Press any key to exit..." -rsn1 user_input
			clear	
			exit 0
			break	
			;;
		-- )
			shift
			break
			;;	
		*)
			break
			;;
	esac
done

# ================================ MAIN GAME =======================================

init_game_data

declare WORD=$( shuf -n 1 $FIVE_WORD_FILE )

if $forget_date || ! played_today
then
	tput civis	
	draw_welcome_screen
	draw_init_screen	
	
	num_guess=0
	declare -a guesses
	declare -a char_stack	
	declare -a color_array	
	declare -A color_map	

	while true
	do
		IFS= read -r -s -n 1 user_input
		case $user_input in
			[a-z]) # user entering letters 
				if [ ${#char_stack[@]} -eq 5 ] 
				then
					continue
				else	
					char_stack+=( $user_input )
					redraw_board $user_input char_stack guesses color_map	
				fi
				;;
			"") # user looking to verify guess
				if [ ${#char_stack[@]} -eq 5 ]
				then
					guess=$( echo ${char_stack[*]} | sed "s/\s*//g" )
					if validate_guess $guess guesses
					then
						get_color_mappings $guess $WORD color_map color_array
						
						user_input="\n"	
						redraw_board $user_input char_stack guesses color_array
					
						color_keyboard_cells color_map
						guesses+=( $guess )
						(( num_guess++ ))
						
						if win_or_lose $guess $num_guess
						then
							break
						fi
						char_stack=()
						color_map=()
					fi
				fi
				;;
			$'\177') # user wants to remove a letter
				[ ${#char_stack[@]} -ne 0 ] && redraw_board $user_input char_stack guesses color_map
				;;
			*)
				;;
		esac	
	done
	date_last_played=$DATE
	serialize_data $guess $date_last_played $num_guess $GAME_DATA_FILE

	read -p "Press a Key when ready..." -rsn1 user_input

	draw_user_stats 
	draw_exit_status
	tput cnorm
	exit 0
else
	echo "Already played today. See you tomorrow 😅"	
	exit 0
fi

# TODO: expand so that multiple users can play game, info serialized and queried on per-player basis
