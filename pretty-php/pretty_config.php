<?php

// set false if you trust pretty.php or just don't need backups
@define("PRETTY_CREATE_BACKUPS", false);

// set false for just one .bak to be created per file
@define("PRETTY_CREATE_MANY_BACKUPS", false);

// use "\t" for actual tabs
@define("PRETTY_TAB", "    ");

// "if ()\n{" vs. "if () {"
@define("PRETTY_LINE_BEFORE_BRACE", true);

// arrays will appear one-element-per-line if enabled
@define("PRETTY_NESTED_ARRAYS", true);

// nested arrays will be left-aligned with their enclosing code if enabled (otherwise they'll be aligned with column 1)
@define("PRETTY_INDENT_NESTED_ARRAYS", true);

// "my_function() ;" vs. "my_function();"
@define("PRETTY_SPACE_BEFORE_SEMICOLON", false);

// "for ($i = 0 ; $i < 10 ; $i++)" vs. "for ($i = 0; $i < 10; $i++)"
@define("PRETTY_SPACE_BEFORE_FOR_SEMICOLON", false);

// "my_function ()" vs. "my_function()"
@define("PRETTY_SPACE_BEFORE_PARENTHESES", false);

// "my_function( $myVar )" vs. "my_function($myVar)"
@define("PRETTY_SPACE_INSIDE_PARENTHESES", false);

// "$myArray []" vs. "$myArray[]"
@define("PRETTY_SPACE_BEFORE_BRACKETS", false);

// "$myArray[ 0 ]" vs. "$myArray[0]"
@define("PRETTY_SPACE_INSIDE_BRACKETS", false);

// "if () :" vs. "if ():"
@define("PRETTY_SPACE_BEFORE_COLON", false);

// consecutive assignments will be aligned on their "=" operator
@define("PRETTY_ALIGN", true);

// how many consecutive assignments before alignment kicks in?
@define("PRETTY_ALIGN_MIN_ROWS", 2);

// this is the acceptable disparity between consecutive assignment variable name lengths
@define("PRETTY_ALIGN_RANGE", 20);

// if enabled, dumps debug dotfiles to the same directory as pretty.php
@define("PRETTY_DEBUG_MODE", false);

// convert single-quoted strings to double-quoted strings
@define("PRETTY_DOUBLE_QUOTE_STRINGS", true);

// de-obfuscate strings containing octal / hex / unicode sequences
@define("PRETTY_DECODE_STRINGS", false);
