#!/bin/bash

declare -A my_assoc_array

my_assoc_array['a']="cat"
my_assoc_array['b']="in"
my_assoc_array['x']="the"
my_assoc_array['t']="hat"

[ "${my_assoc_array['v']}" = "" ] && printf "%s\n\n" "value at 'v' does not exist" || printf "%s\n\n" "value at 'v' does exist" 

printf "%s\n\n" "Length of the assoc array is: ${#my_assoc_array[@]}"

for key in "${!my_assoc_array[@]}"
do
	printf "%s\n" "This is the key: $key"
	printf "%s\n\n" "This is the value: ${my_assoc_array[$key]}"
done

printf "%s\n\n" "Now deleting assoc array..."

my_assoc_array=()
printf "%s\n\n" "Length of the assoc array is: ${#my_assoc_array[@]}"

