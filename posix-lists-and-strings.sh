#!/bin/sh

# POSIX-compliant shell functions for lists and strings manipulation

# Copyright: friendly bits
# github.com/friendly-bits

# NOTE that some functions only work properly with LC_ALL=C
# NOTE that some functions require the $delim and/or the $_nl variables to be set
# NOTE that some functions depend on other functions included in this library

# you can safely ignore shellcheck warnings


# sets some useful variables for colors and ascii delimiter
set_ascii() {
	set -- $(printf '\033[0;31m \033[0;32m \033[1;34m \033[1;33m \033[0;35m \033[0m \35 \t')
	red="$1" green="$2" blue="$3" yellow="$4" purple="$5" nocolor="$6" delim="$7" trim_IFS=" $8"
}

# removes ASCII colors from the input string $1, outpus resulting string
remove_colors() {
	printf %s "$1" | sed -e 's/\x1b\[[0-9;]*m//g'
}

# set IFS to $1 while saving its previous value to variable tagged $2
newifs() {
	eval "IFS_OLD_$2"='$IFS'; IFS="$1"
}

# restore IFS value from variable tagged $1
oldifs() {
	eval "IFS=\"\$IFS_OLD_$1\""
}

# counts elements in input
# fast but may work incorrectly if too many elements provided as input
# ignores empty elements
# 1 - input string
# 2 - delimiter
# 3 - var name for output
fast_el_cnt() {
	el_cnt_var="$3"
	newifs "$2" cnt
	set -- $1
	eval "$el_cnt_var"='$#'
	oldifs cnt
}

tolower() {
	printf %s "$@" | tr 'A-Z' 'a-z'
}

toupper() {
	printf %s "$@" | tr 'a-z' 'A-Z'
}

# primitive alternative to grep
# 1 - input
# 2 - leading '*' wildcard (if required, otherwise use empty string)
# 3 - filter string
# 4 - trailing '*' wildcard (if required, otherwise use empty string)
# 5 - optional var name for output
# outputs the 1st match
# return status is 0 for match, 1 for no match
get_matching_line() {
	newifs "$_nl" gml
	_rv=1; _res=''
	for _line in $1; do
		case "$_line" in $2"$3"$4) _res="$_line"; _rv=0; break; esac
	done
	[ "$5" ] && eval "$5"='$_res'
	oldifs gml
	return $_rv
}

# checks if string $1 is included in list $2, with optional field separator $3 (otherwise uses newline)
# result via return status
is_included() {
	_fs_ii="${3:-"$_nl"}"
	case "$2" in "$1"|"$1$_fs_ii"*|*"$_fs_ii$1"|*"$_fs_ii$1$_fs_ii"*) return 0 ;; *) return 1; esac
}

# adds a string to a list if it's not included yet
# 1 - name of var which contains the list
# 2 - new value
# 3 - optional delimiter (otherwise uses newline)
add2list() {
	a2l_fs="${3:-$_nl}"
	eval "_curr_list=\"\$$1\""
	is_included "$2" "$_curr_list" "$a2l_fs" || eval "$1=\"\${$1}$a2l_fs$2\"; $1=\"\${$1#$a2l_fs}\""
}

# removes duplicate words, removes leading and trailing delimiter, trims in-between extra delimiter characters
# by default expects a newline-delimited list
# (1) - optional -s to delimit both input and output by whitespace
# 1 - var name for output
# 2 - optional input string (otherwise uses prev value)
# 3 - optional input delimiter
# 4 - optional output delimiter
san_str() {
	[ "$1" = '-s' ] && { _del=' '; shift; } || _del="$_nl"
	[ "$2" ] && inp_str="$2" || eval "inp_str=\"\$$1\""

	_sid="${3:-"$_del"}"
	_sod="${4:-"$_del"}"
	_words=
	newifs "$_sid" san
	for _w in $inp_str; do
		add2list _words "$_w" "$_sod"
	done
	eval "$1"='$_words'
	oldifs san
}

# get intersection of lists $1 and $2, with optional field separator $4 (otherwise uses newline)
# output via variable with name $3
get_intersection() {
	[ ! "$1" ] || [ ! "$2" ] && { eval "$3"=''; return 1; }
	_fs_gi="${4:-"$_nl"}"
	_isect=
	for e in $2; do
		is_included "$e" "$1" "$_fs_gi" && add2list _isect "$e" "$_fs_gi"
	done
	eval "$3"='$_isect'
}

# get difference between lists $1 and $2, with optional field separator $4 (otherwise uses newline)
# output via variable with name $3
get_difference() {
	case "$1" in
		'') case "$2" in '') eval "$3"=''; return 1 ;; *) eval "$3"='$2'; return 0; esac ;;
		*) case "$2" in '') eval "$3"='$1'; return 0; esac
	esac
	_fs_gd="${4:-"$_nl"}"
	subtract_a_from_b "$1" "$2" "_diff1" "$_fs_gd"
	subtract_a_from_b "$2" "$1" "_diff2" "$_fs_gd"
	_diff="$_diff1$_fs_gd$_diff2"
	_diff="${_diff#$_fs_gd}"
	eval "$3"='${_diff%$_fs_gd}'
}

# subtract list $1 from list $2, with optional field separator $4 (otherwise uses newline)
# output via variable with name $3
subtract_a_from_b() {
	case "$2" in '') eval "$3"=''; return 0; esac
	case "$1" in '') eval "$3"='$2'; return 0; esac
	_fs_su="${4:-"$_nl"}"
	_subt=
	for e in $2; do
		is_included "$e" "$1" "$_fs_su" || add2list _subt "$e" "$_fs_su"
	done
	eval "$3"='$_subt'
}

# trims leading, trailing and extra in-between spaces
# 1 - output var name
# input via $2, if unspecified then from previous value of $1
trimsp() {
	trim_var="$1"
	newifs "$trim_IFS" trim
	case "$#" in 1) eval "set -- \$$1" ;; *) set -- $2; esac
	eval "$trim_var"='$*'
	oldifs trim
}

# converts whitespace-separated list to newline-separated list
# 1 - var name for output
# input via $2, if not specified then uses current value of $1
sp2nl() {
	var_stn="$1"
	[ $# = 2 ] && _inp="$2" || eval "_inp=\"\$$1\""
	newifs "$trim_IFS" stn
	set -- $_inp
	IFS="$_nl"
	eval "$var_stn"='$*'
	oldifs stn
}

# converts newline-separated list to whitespace-separated list
# 1 - var name for output
# input via $2, if not specified then uses current value of $1
nl2sp() {
	var_nts="$1"
	[ $# = 2 ] && _inp="$2" || eval "_inp=\"\$$1\""
	newifs "$_nl" nts
	set -- $_inp
	IFS=' '
	eval "$var_nts"='$*'
	oldifs nts
}

# trims extra whitespaces, discards empty args
# output via variable '_args'
# output string is delimited with $delim
san_args() {
	_args=
	for arg in "$@"; do
		trimsp arg
		[ "$arg" ] && _args="$_args$arg$delim"
	done
}

# converts unsigned integer to either [x|xK|xM|xT|xQ] or [xB|xKiB|xMiB|xTiB|xPiB], depending on $2
# if result is not an integer, outputs up to 2 digits after decimal point
# 1 - int
# 2 - (optional) "bytes"
num2human() {
	i=${1:-0} s=0 d=0
	case "$2" in bytes) m=1024 ;; '') m=1000 ;; *) return 1; esac
	case "$i" in *[!0-9]*) printf '%s\n' "num2human: Invalid unsigned integer '$i'." >&2; return 1; esac
	for S in B KiB MiB TiB PiB; do
		[ $((i > m && s < 4)) = 0 ] && break
		d=$i
		i=$((i/m))
		s=$((s+1))
	done
	[ -z "$2" ] && { S=${S%B}; S=${S%i}; [ "$S" = P ] && S=Q; }
	d=$((d % m * 100 / m))
	case $d in
		0) printf "%s%s\n" "$i" "$S"; return ;;
		[1-9]) f="02" ;;
		*0) d=${d%0}; f="01"
	esac
	printf "%s.%${f}d%s\n" "$i" "$d" "$S"
}


LC_ALL=C
_nl='
'

set_ascii
