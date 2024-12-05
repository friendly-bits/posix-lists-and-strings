#!/bin/sh

# POSIX-compliant shell functions for lists and strings manipulation

# Copyright: friendly bits
# github.com/friendly-bits

# NOTE that some functions only work properly with LC_ALL=C
# NOTE that some functions require the $delim and/or the $_nl variables to be set
# NOTE that some functions depend on other functions included in this library

# you can safely ignore shellcheck warnings


# sets some variables for colors, symbols and delimiter
set_ansi() {
	set -- $(printf '\033[0;31m \033[0;32m \033[1;34m \033[1;33m \033[0;35m \033[0m \35')
	red="$1" green="$2" blue="$3" yellow="$4" purple="$5" nocolor="$6" delim="$7"
}

# removes colors from the input string $1, outpus resulting string
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

# Checks if input string needs conversion and if it does then converts case using tr
# Requires that $LC_ALL be set to "C". Will not work correctly with other locales.
# 1 - var name for output
# 2 - toupper|tolower
# 3 - string
conv_case() {
	outvar_cc="$1"
	case "$2" in
		toupper) tr_1='a-z' tr_2='A-Z' ;;
		tolower) tr_1='A-Z' tr_2='a-z'
	esac
	case "$3" in
		*[$tr_1]*) conv_res="$(printf %s "$3" | tr "$tr_1" "$tr_2")" ;;
		*) conv_res="$3"
	esac
	eval "$outvar_cc=\"$conv_res\""
}

# 1 - var name for output
# 2 - optional string (otherwise uses prev value)
# Requires that $LC_ALL be set to "C". Will not work correctly with other locales.
tolower() {
	in_cc="$2"
	[ $# = 1 ] && eval "in_cc=\"\$$1\""
	conv_case "$1" tolower "$in_cc"
}

# 1 - var name for output
# 2 - optional string (otherwise uses prev value)
# Requires that $LC_ALL be set to "C". Will not work correctly with other locales.
toupper() {
	in_cc="$2"
	[ $# = 1 ] && eval "in_cc=\"\$$1\""
	conv_case "$1" toupper "$in_cc"
}

# primitive alternative to grep, may not work correctly if too many lines are provided as input
# outputs only the 1st match
# return status is 0 for match, 1 for no match
# 1 - input
# 2 - leading '*' wildcard (if required, otherwise use empty string)
# 3 - filter string
# 4 - trailing '*' wildcard (if required, otherwise use empty string)
# 5 - optional var name for output
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

# Checks if string $1 contains characters: ['"\]. If it does, string is deemed not safe to use with eval
# output via return value: 0 - safe, 1 - not safe
is_str_safe() {
	case "$1" in *'\'*|*'"'*|*\'*) return 1; esac
 	:
}

# checks if $1 is alphanumeric (underlines allowed)
# output via return value: 0 - alphanumeric, 1 - non-alphanumeric
is_alphanum() {
	case "$1" in *[!A-Za-z0-9_]*)
		return 1
	esac
	:
}

# checks if string $1 is included in list $2, with optional field separator $3 (otherwise uses newline)
# result via return status
is_included() {
	_fs_ii="${3:- }"
	case "$2" in "$1"|"$1$_fs_ii"*|*"$_fs_ii$1"|*"$_fs_ii$1$_fs_ii"*) return 0 ;; *) return 1; esac
}

# adds a string to a list if it's not included yet
# 1 - name of var which contains the list
# 2 - new value
# 3 - optional delimiter (otherwise uses whitespace)
# returns 2 if value was already included, 1 if bad var name, 0 otherwise
add2list() {
	is_alphanum "$1" || return 1
	a2l_fs="${3:- }"
	eval "_curr_list=\"\$$1\""
	is_included "$2" "$_curr_list" "$a2l_fs" && return 2
	eval "$1=\"\${$1}$a2l_fs\""'$2'"; $1=\"\${$1#$a2l_fs}\""
	return 0
}

# removes duplicate words, removes leading and trailing delimiter, trims in-between extra delimiter characters
# by default expects a whitespace-delimited list
# (1) - optional -n to delimit both input and output by newline
# 1 - var name for output
# 2 - optional input string (otherwise uses prev value)
# 3 - optional input delimiter
# 4 - optional output delimiter
san_str() {
	[ "$1" = '-n' ] && { _del="$_nl"; shift; } || _del=' '
	[ "$2" ] && inp_str="$2" || eval "inp_str=\"\$$1\""
	is_str_safe "$inp_str" || { unset "$1"; return 1; }
	_sid="${3:-"$_del"}"
	_sod="${4:-"$_del"}"
	_words=
	newifs "$_sid" san
	for _w in $inp_str; do
		add2list _words "$_w" "$_sod"
	done

	eval "$1"='$_words'
	oldifs san
	:
}

# get intersection of lists $1 and $2, with optional field separator $4 (otherwise uses whitespace)
# output via variable with name $3
get_intersection() {
	gi_out="${3:-___dummy}"
	[ ! "$1" ] || [ ! "$2" ] && { unset "$gi_out"; return 1; }
	_fs_gi="${4:-" "}"
	_isect=
	newifs "$_fs_gi" _fs_gi
	for e in $2; do
		is_included "$e" "$1" "$_fs_gi" && add2list _isect "$e" "$_fs_gi"
	done
	eval "$gi_out"='$_isect'
	oldifs _fs_gi
}

# get difference between lists $1 and $2, with optional field separator $4 (otherwise uses whitespace)
# output via optional variable with name $3
# returns status 0 if lists match, 1 if not
get_difference() {
	gd_out="${3:-___dummy}"
	case "$1" in
		'') case "$2" in '') unset "$gd_out"; return 0 ;; *) eval "$gd_out"='$2'; return 1; esac ;;
		*) case "$2" in '') eval "$gd_out"='$1'; return 1; esac
	esac
	_fs_gd="${4:-" "}"
	subtract_a_from_b "$1" "$2" _diff1 "$_fs_gd"
	subtract_a_from_b "$2" "$1" _diff2 "$_fs_gd"
	_diff="$_diff1$_fs_gd$_diff2"
	_diff="${_diff#"$_fs_gd"}"
	eval "$gd_out"='${_diff%$_fs_gd}'
	[ "$_diff1$_diff2" ] && return 1 || return 0
}

# subtract list $1 from list $2, with optional field separator $4 (otherwise uses whitespace)
# output via optional variable with name $3
# returns status 0 if the result is null, 1 if not
subtract_a_from_b() {
	sab_out="${3:-___dummy}"
	case "$2" in '') unset "$sab_out"; return 0; esac
	case "$1" in '') eval "$sab_out"='$2'; [ ! "$2" ]; return; esac
	_fs_su="${4:-" "}"
	rv_su=0 _subt=
	newifs "$_fs_su" _fs_su
	for e in $2; do
		is_included "$e" "$1" "$_fs_su" || { add2list _subt "$e" "$_fs_su"; rv_su=1; }
	done
	eval "$sab_out"='$_subt'
	oldifs _fs_su
	return $rv_su
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

# 1 - input delimiter
# 2 - output delimiter
# 3 - var name for output
# input via $4, if not specified then uses current value of $3
conv_delim() {
    out_del="$2"
    var_cd="$3"
    [ $# -ge 4 ] && _inp="$4" || eval "_inp=\"\$$3\""
    newifs "$1" cd
    set -- $_inp
    IFS="$out_del"
    eval "$var_cd"='$*'
    oldifs cd
}

# converts whitespace-separated list to newline-separated list
# 1 - var name for output
# input via $2, if not specified then uses current value of $1
sp2nl() {
	conv_delim ' ' "$_nl" "$@"
}

# converts newline-separated list to whitespace-separated list
# 1 - var name for output
# input via $2, if not specified then uses current value of $1
nl2sp() {
	conv_delim "$_nl" ' ' "$@"
}

# trims extra whitespaces, discards empty args
# checks if args are safe to use with eval (must not contain ['"\] characters). stops processing args and returns 1 if unsafe arg is encountered.
# output via variable '_args'
# output string is delimited with $delim
san_args() {
	_args=
	for arg in "$@"; do
		is_str_safe "$arg" || return 1
		trimsp arg
		[ "$arg" ] && _args="$_args$arg$delim"
	done
 	:
}

# converts unsigned integer to either [x|xK|xM|xB|xT] or [xB|xKiB|xMiB|xGiB|xTiB], depending on $2
# if result is not an integer, outputs up to 2 digits after decimal point
# 1 - int
# 2 - (optional) "bytes"
num2human() {
	i=${1:-0} s=0 d=0
	case "$2" in bytes) m=1024 ;; '') m=1000 ;; *) return 1; esac
	case "$i" in *[!0-9]*)  printf '%s\n' "num2human: Invalid unsigned integer '$i'." >&2; return 1; esac
	for S in B KiB MiB GiB TiB; do
		[ $((i > m && s < 4)) = 0 ] && break
		d=$i
		i=$((i/m))
		s=$((s+1))
	done
	[ -z "$2" ] && { S=${S%B}; S=${S%i}; [ "$S" = G ] && S=B; }
	d=$((d % m * 100 / m))
	case $d in
		0) printf "%s%s\n" "$i" "$S"; return ;;
		[1-9]) fp="02" ;;
		*0) d=${d%0}; fp="01"
	esac
	printf "%s.%${fp}d%s\n" "$i" "$d" "$S"
}

# compares lines in files $1 and $2, regardless of order
# uses awk for fast processing of large files
# ignores empty lines
# returns 0 for no diff, 1 for diff, 2 for error
compare_files() {
	awk_cmp() {
		awk 'NF==0{next} NR==FNR {A[$0]=1;a++;next} {b++} !A[$0]{r=1;exit} END{if(!a&&!b){exit 0};if(!a||!b){exit 1};exit r}' r=0 "$1" "$2"
	}

	[ -f "$1" ] && [ -f "$2" ] || { printf '%s\n' "compare_files: file '$1' or '$2' does not exist." >&2; return 2; }
	awk_cmp "$1" "$2" && awk_cmp "$2" "$1"
}


LC_ALL=C
_nl='
'

set_ansi
