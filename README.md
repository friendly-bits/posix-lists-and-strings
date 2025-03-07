# POSIX LISTS AND STRINGS
POSIX-compliant shell functions for processing of lists and strings.

The main idea is to implement in native, fast and secure shell code functionality for processing lists and strings. The implementation avoids calling external tools as much as possible in order to minimize dependencies and improve performance, and avoids creating subshells which are known to be slow.

**If you find this code useful, please consider giving this repository a star - this helps other people to find it.**

## General functions
- set_ansi() : set some global variables for colors, symbols and delimiter
- newifs() : set IFS to `$1` while saving its previous value to variable tagged `$2`
- oldifs() : restore IFS value from variable tagged `$1`
- conv_case() : implements optimized case conversion (only creates subshell if input needs to be converted)
- tolower() : wrapper for `conv_case()`, specifically converting upper to lower case
- toupper() : wrapper for `conv_case()`, specifically converting lower to upper case
- get_matching_line() : primitive alternative to grep, implemented with `case` in order to avoid subshell. Fast for small'ish inputs.
- san_args(): trim extra whitespaces, discard empty args
- compare_files(): efficiently compare files `$1` and `$2`, ignoring empty lines, duplicate lines and lines order. Uses awk for fast processing. Output via return code.
- replace_lines_seq(): replace lines sequence `$1` with `$2` in file `$3`, output to STDOUT. Uses awk.

## String processing
- is_str_safe() : check if string `$1` contains characters `'"\`. If it does, string is deemed not safe to use with eval. Output via return code.
- is_alphanum() : check if string `$1` is alphanumeric (underlines allowed). Output via return code.
- trimsp() : trim leading, trailing and extra in-between spaces
- remove_colors() : remove ANSI colors from the input string
- san_str() : remove duplicate words, remove leading and trailing delimiter, trim in-between extra delimiter characters
- conv_delim(): convert delimiter in input string from `$1` to `$2`
- sp2nl(): wrapper for `conv_delim()` converting whitespaces to newlines
- nl2sp(): wrapper for `conv_delim()` converting newlines to whitespaces
- num2human(): convert unsigned integer to either [x|xK|xM|xB|xT] or [xB|xKiB|xMiB|xGiB|xTiB], depending on `$2`

## Lists processing
- fast_el_cnt() : counts elements in input `$1` (separated by delimiter `$2`) without creating a subshell, fast for small'ish inputs
- is_included() : check if string `$1` is included in list `$2`, with optional delimiter `$3` (otherwise assumes whitespace)
- add2list() : add a string to a list if it's not included yet
- get_intersection() : get intersection of lists `$1` and `$2`, with optional delimiter `$4` (otherwise assumes whitespace)
- get_difference() : get difference between lists `$1` and `$2`, with optional delimiter `$4` (otherwise assumes whitespace)
- subtract_a_from_b() : subtract list `$1` from list `$2`, with optional delimiter `$4` (otherwise assumes whitespace)

All functions are implemented in shell code (no external binaries called), except:
- remove_colors() which uses sed
- conv_case(), tolower() and toupper() which use tr
- compare_files(), replace_lines_seq() which use awk

Many functions use eval in order to avoid creating subshells. Some functions check input with is_str_safe() to make sure that input won't cause issues with eval.

All functions are tested and working.

Read code comments to learn how to use the functions.

If you are interested in POSIX-compliant shell code, check out my other repositories.
