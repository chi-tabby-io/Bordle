#!/bin/bash 

# global var definitions
#TODO: perhaps search for the word file on Linux systems, else download the word file from a link
BASE_WORD_FILE=~/dict/english3.txt FIVE_WORD_FILE=~/dict/five_lett_dict.txt
GAME_DATA_FILE=./wordle_game_data.txt

# make sure we're looking at only five letter words
if ! [ -s $FIVE_WORD_FILE ]
then
	touch $FIVE_WORD_FILE
	egrep "^[a-z]{5}\$" $BASE_WORD_FILE > $FIVE_WORD_FILE
fi
	
WORD=$( shuf -n 1 $FIVE_WORD_FILE )

WIDTH=$( tput cols )
HEIGHT=$( tput lines )

declare -a BORDLE_TEXT	
BORDLE_TEXT+=( "██████╗  ██████╗ ██████╗ ██████╗ ██╗     ███████╗" ) 
BORDLE_TEXT+=( "██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██║     ██╔════╝" )
BORDLE_TEXT+=( "██████╔╝██║   ██║██████╔╝██║  ██║██║     █████╗  " )
BORDLE_TEXT+=( "██╔══██╗██║   ██║██╔══██╗██║  ██║██║     ██╔══╝  " )
BORDLE_TEXT+=( "██████╔╝╚██████╔╝██║  ██║██████╔╝███████╗███████╗" )
BORDLE_TEXT+=( "╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝" )

GAME_RULES_STR="Game Rules:"
GAME_RULES_LEN=${#GAME_RULES_STR}

INSTRUCTIONS+=( "1. I have come up with a 5 letter word. You must guess it correctly in 6 attempts.        " )
INSTRUCTIONS+=( "2. After each attempt, I will give you feedback on your guess, according to the following:" )
INSTRUCTIONS+=( "   a. If a letter is in the word but in the wrong position, I will mark it orange.        " )
INSTRUCTIONS+=( "   b. If a letter is in the word and in the correct position, I will mark it green.       " )
INSTRUCTIONS+=( "   c. If a letter is not in the word, I will not mark it at all.                          " )
INSTRUCTIONS+=( "3. Repeats are allowed.                                                                   " )

CELL_WIDTH=10
CELL_HEIGHT=4
N_CELL_WIDE=5
N_CELL_HIGH=6
N_CHAR_WIDTH=$(( CELL_WIDTH * N_CELL_WIDE + N_CELL_WIDE + 1 ))	
N_CHAR_HEIGHT=$(( CELL_HEIGHT * N_CELL_HIGH + N_CELL_HIGH + 1 )) 

# ========================= TUI FUNCTIONS ===============================

# $1 == cursor_x $2 == cursor_y
print_wordle_text() {
	cursor_x=$1
	cursor_y=$2
	
	tput cup $cursor_x $cursor_y
	for row in "${BORDLE_TEXT[@]}"
	do
		echo "$row"
		(( cursor_x++ ))	
		tput cup $cursor_x $cursor_y
	done
}

print_welcome_screen() {
	clear
	welcome_str="Welcome to:"

	local cursor_x=$((( HEIGHT / 6 ) -  6 ))
	local cursor_y=$((( WIDTH / 2 ) - ( ${#welcome_str} / 2  )))
	tput cup $cursor_x $cursor_y
	echo $welcome_str

	(( cursor_x += 3 ))
	(( cursor_y = ( WIDTH / 2 ) - ( ${#BORDLE_TEXT[1]} / 2 ) ))	
	print_wordle_text $cursor_x $cursor_y
	
	(( cursor_x += 2 ))	
	(( cursor_y = ( WIDTH / 2 ) - ( GAME_RULES_LEN / 2 ) ))
	print_instructions $cursor_x $cursor_y 

	user_prompt="[INFO] To continue, press any key"
	(( cursor_x += 2 ))	
	(( cursor_y = ( WIDTH / 2 ) - ( ${#user_prompt} / 2 ) ))
	tput cup $cursor_x $cursor_y
	read -p "$user_prompt" -rsn1 user_input
	clear
}

# $1 == cursor_x $2 == cursor_y 
print_instructions() {
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
print_empty_table() {
	cursor_x=$1
	cursor_y=$2	

	tput cup $cursor_x $cursor_y	
	for (( i=1; i<=$N_CHAR_HEIGHT; i++ ))	
	do
		if [ $(( i % ( CELL_HEIGHT + 1 ) )) -eq 1 ]
		then	
			for (( j=1; j<=$N_CHAR_WIDTH; j++ )) 
			do
				[ $(( j % ( CELL_WIDTH + 1 ) )) -eq 1 ] && echo -n "+" || echo -n "-" 
			done
		else
			for (( j=1; j<=$N_CHAR_WIDTH; j++ )) 
			do
				[ $(( j % ( CELL_WIDTH + 1 ) )) -eq 1 ] && echo -n "|" || echo -n " " 
			done
			# do some shit
		fi
		echo	
		(( cursor_x++ ))
		tput cup $cursor_x $cursor_y	
	done
}

#print_keyboard() {
#	#TODO: implement me :)
#}

init_game_screen() {
	clear	
	local cursor_x=3
	local cursor_y
	(( cursor_y = WIDTH / 2 - ( ${#BORDLE_TEXT[1]} / 2 ) ))	
	print_wordle_text $cursor_x $cursor_y	
	
	(( cursor_x += 2 ))
	(( cursor_y = ( WIDTH / 2 ) - ( N_CHAR_WIDTH / 2 ) ))
	print_empty_table $cursor_x $cursor_y
#	# OPTIONAL: print_keyboard()	
}

# $1 == input $2 == char_stack $3 == guesses $4 == color_codes
update_board() {
	input=$1	
	char_stack=$2
	guesses=$3
	color_codes=$4
	local cursor_x=$(( 3 + ${#BORDLE_TEXT[@]} + 2 + 1 ))
	local cursor_y=$(( ( WIDTH / 2 ) - ( N_CHAR_WIDTH / 2 ) + 1 ))

	ROW_NUM=$(( ( ${#guesses[@]} - 1 ) % 6 ))
	COL_NUM=$(( ( ${#char_stack[@]} - 1 ) % 5 ))
	(( cursor_x += ROW_NUM * ( CELL_HEIGHT + 1 ) ))
	(( cursor_y += COL_NUM * ( CELL_WIDTH + 1 ) ))

	case $input in
		[a-z]) # user input letter
			# echo "alpha"	
			tput cup $cursor_x $cursor_y
			echo $input 
			;;
		"\n") # user wants to validate guess
			# not reaching this code ==> rethink how to detect newline	
			# echo "enter"	
			color_cells $char_stack $color_codes $ROW_NUM
			;;
		$'\177') # user wants to erase last letter
			# (( cursor_y -= CELL_WIDTH + 1 )) 
			# echo "backspace"	
			unset char_stack[-1] 
			tput cup $cursor_x $cursor_y
			echo " "
			;;
		*)
			echo "anything"	
			return	
			;;	
	esac
}

# $1 == char_stack $2 == color_codes $3 == ROW_NUM
color_cells() {
	char_stack=$1	
	color_codes=$2
	ROW_NUM=$3
	local init_cursor_x=$(( 3 + ${#BORDLE_TEXT[@]} + 2 + 1 + ROW_NUM * ( CELL_HEIGHT + 1 ) ))
	local init_cursor_y=$(( ( WIDTH / 2 ) - ( N_CHAR_WIDTH / 2 ) + 1 ))
	local cursor_x=$init_cursor_x
	local cursor_y=$init_cursor_y

	for (( i=0;i<$N_CELL_WIDE;i++ ))
	do
		(( cursor_x = $init_cursor_x ))	
		(( cursor_y = $init_cursor_y + $i * ( $CELL_WIDTH + 1 ) ))
		# set background color, foreground color
		tput setab ${color_codes[$i]}	
		for (( j=0;j<$CELL_WIDTH;j++ ))
		do
			(( cursor_y += $j ))
			for (( k=0;k<$CELL_HEIGHT;k++ ))
			do
				(( cursor_x += $k ))
				tput cup $cursor_x $cursor_y
				[ $j -eq 0 ] && [ $k -eq 0 ] && echo "${char_stack[$i]}" || echo " "
				(( cursor_x = $init_cursor_x))	
			done
			(( cursor_y = $init_cursor_y + $i * ( $CELL_WIDTH + 1 ) ))
			sleep 0.05 
		done
	done
 	tput sgr0
}

# $1 == status_msg
update_status() {
	status_msg=$1
	local init_cursor_x=$(( 3 + ${#BORDLE_TEXT[@]} + 2 + 1 + N_CHAR_HEIGHT ))
	local init_cursor_y=0 
	local cursor_x=$init_cursor_x
	local cursor_y=$init_cursor_y 
	
	tput cup $cursor_x $cursor_y
	tput el	

	(( cursor_y = ( WIDTH  / 2 ) - ${#status_msg} / 2 ))
	tput cup $cursor_x $cursor_y
	echo "$status_msg"
}

print_exit_screen() {
	local init_cursor_x=$(( 3 + ${#BORDLE_TEXT[@]} + 2 + 1 + N_CHAR_HEIGHT + 2 ))
	local init_cursor_y=0 
	local cursor_x=$init_cursor_x
	local cursor_y=$init_cursor_y 
	
	tput cup $cursor_x $cursor_y
	
	read -p "Press any key to exit" -rsn1 user_input
	(( cursor_x++ ))	
	tput cup $cursor_x $cursor_y	
	echo "Exiting..."
	sleep 0.75
	clear
}

# ====================== UTILITY FUNCTIONS ==============================

# $1 == guess $2 == guesses 
validate_guess() {
	guesses=$2	
	local status_msg
		
	if [ ${#1} -ne 5 ] 
	then
		status_msg="Guess must be a 5 letter word"
		exit_status=1	
	elif ! [[ $1 =~ [a-z]{5} ]]
	then
		status_msg="Guess must be alphabetical only."	
		exit_status=1	
	elif ! grep -Fxq "$1" $FIVE_WORD_FILE
	then
		status_msg="'$1' was not found in word list!"
		exit_status=1	
	elif [[ ${guesses[*]} =~ (^|[[:space:]])"$1"($|[[:space:]]) ]] 
	then
		status_msg="'$1' already guessed!"
		exit_status=1
	else
		exit_status=0	
	fi
	
	[ $exit_status -eq 1 ] && update_status "$status_msg"	
	return $exit_status	
}

win_or_lose() {
	local status_msg	
	local exit_status	
	if [ $1 = $WORD ]
	then
		status_msg="You won! Congrats :)"
		exit_status=0	
	elif [ $2 -eq 6 ]
	then
		status_msg="You lost 😭😭😭 the word was $WORD"	
		exit_status=0	
	else
		exit_status=1	
	fi
	update_status "$status_msg" && return $exit_status
}

# FIXME: VERY BAD CODING PRACTICE: YIKES FUNCTION BELOW
# $1 == guess $2 == num_guess
won() {
	if [[ $1 == $WORD && ! $2 > 6 ]] 
	then
		echo 0
	else
		echo 1
	fi	
}

# tput colors to use:
# green == 2
# yellow == 3
# $1 == guess $2 == word $3 == color_codes
compare_guess_to_word() { 
	word=$2
	guess=$1
	color_codes=$3
	# echo [DEBUG] Word is \'$word\'
	for (( i=0;i<${#guess};i++ ))
	do
		guess_i=${guess:i:1}
		if [[ $word =~ "$guess_i" ]]
		then
			match=0
			match_pos=0
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
				color_codes[$i]=2	
			else
				color_codes[$i]=3	
			fi
		else
			color_codes[$i]=9 # might change this value later
		fi
	done
}

# $1 == GAME_DATA_FILE
reset_game_data() {
	sed -i "s/date : [0-9]*/date : 0/" $1
	sed -i "s/games_played : [0-9]*/games_played : 0/" $1
	sed -i "s/games_won : [0-9]*/games_won : 0/" $1	
	for i in {1..6}
	do
		sed -i "s/games_in_$i : [0-9]*/games_in_$i : 0/" $1
	done
}

# $1 == guess $2 == date_last_played $3 == num_guess $4 GAME_DATA_FILE 
serialize_data() {
	date_last_played_info=$( cat $4 | grep "^date" )
	sed -i "s/$date_last_played_info/date : $2/" $4
	if [[ $1 == $WORD && ! $3 > 6 ]] 
	then
		this_game_freq_info=$( cat $4 | grep "^games_in_$3" )
		this_game_freq=$( echo $this_game_freq_info | awk '{print $3}' )
		(( this_game_freq++ ))
		sed -i "s/$this_game_freq_info/games_in_$3 : $this_game_freq/g" $4	
		games_won_info=$( cat $4 | grep "^games_won" )
		games_won=$( echo $games_won_info | awk '{print $3}' )
		(( games_won++ ))
		sed -i "s/$games_won_info/games_won : $games_won/" $4
	fi
	games_played_info=$( cat $4 | grep "^games_played" )
	games_played=$( echo $games_played_info | awk '{print $3}' )
	(( games_played++ ))
	sed -i "s/$games_played_info/games_played : $games_played/" $4	
}

date_last_played=$( cat $GAME_DATA_FILE  | grep "^date" | awk '{print $3}' ) 
DATE=$( date +%s )
TIME_DIFF=$(( $DATE - $date_last_played ))
OFFSET=$( date +%::z | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}' )
TIME_LEFT_TODAY=$(( 86400 - (( $date_last_played + $OFFSET ) % 86400 ) ))

played_today() {
		if [ $TIME_DIFF -lt $TIME_LEFT_TODAY ]
	then
		return 0
	else
		return 1 
	fi
}

print_welcome_screen

if [ $( played_today ) -eq 0 ]
then
	echo [ERROR] Already played today. See you tomorrow :\)	
else
	init_game_screen	
	
	num_guess=0
	declare -a guesses
	declare -a char_stack	
	declare -a color_codes	
	
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
					update_board $user_input $char_stack $guesses $color_codes	
				fi
				;;
			"") # user looking to verify guess
				if [ ${#char_stack[@]} -eq 5 ]
				then
					guess=$( echo ${char_stack[*]} | sed "s/\s*//g" )
					if validate_guess $guess $guesses
					then
						compare_guess_to_word $guess $WORD $color_codes
						user_input="\n"	
						update_board $user_input $char_stack $guesses $color_codes
						guesses+=( $guess )
						(( num_guess++ ))
						
						if win_or_lose $guess $num_guess
						then
							break
						fi
						char_stack=()
						color_codes=()
					fi
				fi
				;;
			$'\177') # user wants to remove a letter
				[ ${#char_stack[@]} -ne 0 ] && update_board $user_input $char_stack $guesses $color_codes
				;;
			*)
				;;
		esac	
	done
	date_last_played=$DATE
	serialize_data $guess $date_last_played $num_guess $GAME_DATA_FILE
fi
# reset_game_data $GAME_DATA_FILE # for debugging
print_exit_screen
# TODO: create user-reachable context menu to display char guessed
#		and their approp highlights, in QWERTY layout
# TODO: create a man page or -h --help -u --usage page for commands
#		available to user
# TODO: expand so that multiple users can play game, info serialized and queried on per-player basis
