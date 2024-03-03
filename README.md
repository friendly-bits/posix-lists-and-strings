# POSIX LISTS AND STRINGS
POSIX-compatible shell functions for operations on lists and strings

Included functions:
- set_ascii()
- remove_colors()
- newifs()
- oldifs()
- fast_el_cnt()
- tolower()
- toupper()
- get_matching_line()
- trimsp()
- san_str()
- is_included()
- get_intersection()
- get_difference()
- subtract_a_from_b()
- sp2nl()
- nl2sp()
- san_args()
- num2human()

All functions are implemented in shell code (no external binaries called), except remove_colors() which uses sed, and tolower() and toupper() which use tr.

All functions are tested and working.

Read code comments to understand what each function is doing and how to use it.

If you are interested in POSIX-compliant shell code, check out my other repositories.

**You can show your appreciation by giving this repository a star.**
