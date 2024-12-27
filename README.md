# POSIX LISTS AND STRINGS
POSIX-compliant shell functions for processing of lists and strings.

The main idea is to implement in native, fast and secure shell code functionality for processing lists and strings. The implementation avoids calling external tools as much as possible in order to minimize dependencies and improve performance, and avoids creating subshells which are known to be slow.

**If you find this code useful, please consider giving this repository a star - this helps other people to find it.**

Included functions:
- set_ansi()
- remove_colors()
- newifs()
- oldifs()
- fast_el_cnt()
- conv_case()
- tolower()
- toupper()
- get_matching_line()
- is_str_safe()
- is_alphanum()
- is_included()
- add2list()
- san_str()
- get_intersection()
- get_difference()
- subtract_a_from_b()
- trimsp()
- conv_delim()
- sp2nl()
- nl2sp()
- san_args()
- num2human()
- compare_files()
- replace_lines_seq()

All functions are implemented in shell code (no external binaries called), except:
- remove_colors() which uses sed
- conv_convert(), tolower() and toupper() which use tr
- compare_files(), replace_lines_seq() which use awk

Many functions use eval in order to avoid creating subshells. Some functions check input with is_str_safe() to make sure that input won't cause issues with eval.

All functions are tested and working.

Read code comments to understand what each function is doing and how to use it.

If you are interested in POSIX-compliant shell code, check out my other repositories.
