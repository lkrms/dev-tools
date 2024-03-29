<?php

defined("T_AMPERSAND_FOLLOWED_BY_VAR_OR_VARARG") || define("T_AMPERSAND_FOLLOWED_BY_VAR_OR_VARARG", 10001);
defined("T_AMPERSAND_NOT_FOLLOWED_BY_VAR_OR_VARARG") || define("T_AMPERSAND_NOT_FOLLOWED_BY_VAR_OR_VARARG", 10002);
defined("T_BAD_CHARACTER") || define("T_BAD_CHARACTER", 10003);
defined("T_COALESCE_EQUAL") || define("T_COALESCE_EQUAL", 10004);
defined("T_NAME_FULLY_QUALIFIED") || define("T_NAME_FULLY_QUALIFIED", 10005);
defined("T_SPACESHIP") || define("T_SPACESHIP", 10006);

// these tokens are purged before processing begins
$tSkip = array(
    T_WHITESPACE,
    T_BAD_CHARACTER,
);

$tKeywords = array(
    T_AS,
    T_CALLABLE,
    T_CLONE,
    T_ECHO,
    T_EVAL,
    T_EXIT,
    T_GLOBAL,
    T_GOTO,
    T_INCLUDE,
    T_INCLUDE_ONCE,
    T_INSTANCEOF,
    T_LIST,
    T_NEW,
    T_PRINT,
    T_REQUIRE,
    T_REQUIRE_ONCE,
    T_THROW,
    T_INSTEADOF,

);

$tControlWithParentheses = array(
    T_ELSEIF,
    T_FOR,
    T_FOREACH,
    T_IF,
    T_SWITCH,
    T_TRY,
    T_WHILE,
);

$tControlNoParentheses = array(
    T_DO,
    T_ELSE,
);

$tControlOptionalParentheses = array(
    T_CATCH,
);

$tSimpleControl = array(
    T_BREAK,
    T_CONTINUE,
    T_RETURN,
    T_YIELD,
    T_YIELD_FROM,
);

$tControlOptions = array(
    T_CATCH,
    T_ELSE,
    T_ELSEIF,
);

$tAltControl = array(
    T_ENDDECLARE,
    T_ENDFOR,
    T_ENDFOREACH,
    T_ENDIF,
    T_ENDSWITCH,
    T_ENDWHILE,
);

$tAssignmentOperators = array(
    "=",
    T_PLUS_EQUAL,
    T_MINUS_EQUAL,
    T_MUL_EQUAL,
    T_DIV_EQUAL,
    T_MOD_EQUAL,
    T_POW_EQUAL,
    T_AND_EQUAL,
    T_OR_EQUAL,
    T_XOR_EQUAL,
    T_SL_EQUAL,
    T_SR_EQUAL,
    T_CONCAT_EQUAL,
    T_COALESCE_EQUAL,
);

$tArithmeticOperators = array(
    "+",
    "-",
    "*",
    "/",
    "%",
    T_POW
);

$tComparisonOperators = array(
    "<",
    ">",
    T_IS_EQUAL,
    T_IS_GREATER_OR_EQUAL,
    T_IS_IDENTICAL,
    T_IS_NOT_EQUAL,
    T_IS_NOT_IDENTICAL,
    T_IS_SMALLER_OR_EQUAL,
    T_SPACESHIP,
);

$tLogicalOperators = array(
    T_LOGICAL_AND,
    T_LOGICAL_OR,
    T_LOGICAL_XOR,
    "!",
    T_BOOLEAN_AND,
    T_BOOLEAN_OR,
);

$tBitwiseOperators = array(
    "&",
    "|",
    "^",
    "~",
    T_SL,
    T_SR,
    T_AMPERSAND_FOLLOWED_BY_VAR_OR_VARARG,
    T_AMPERSAND_NOT_FOLLOWED_BY_VAR_OR_VARARG,
);

$tSpecialOperators = array(
    ".",
    "?",
    T_COALESCE,
    T_DOUBLE_ARROW,
);

$tCasts = array(
    T_ARRAY_CAST,
    T_BOOL_CAST,
    T_DOUBLE_CAST,
    T_INT_CAST,
    T_OBJECT_CAST,
    T_STRING_CAST,
    T_UNSET_CAST,
);

$tDeclarations = array(
    T_ABSTRACT,
    T_CLASS,
    T_CONST,
    T_EXTENDS,
    T_FINAL,
    T_FUNCTION,
    T_IMPLEMENTS,
    T_INTERFACE,
    T_NAMESPACE,
    T_PRIVATE,
    T_PUBLIC,
    T_PROTECTED,
    T_STATIC,
    T_TRAIT,
    T_USE,
    T_VAR,
);

$tCollapsibleDeclarations = array(
    T_CONST,
    T_USE,
    T_VAR,
);

$tVisibility = array(
    T_PRIVATE,
    T_PROTECTED,
    T_PUBLIC,
);

$tNoTrim = array(
    T_ENCAPSED_AND_WHITESPACE,
    T_INLINE_HTML,
    T_OPEN_TAG,
    T_OPEN_TAG_WITH_ECHO,
);

// only remove whitespace from the right of these (e.g. "<?php", except PHP parses "<?php " as a different token)
$tTrimRight = array();

// only remove whitespace from the left of these
$tTrimLeft = array(
    T_CLOSE_TAG,
);

$tComments = array(
    T_COMMENT,
    T_DOC_COMMENT,
);

$tControl      = array_merge($tControlWithParentheses, $tControlNoParentheses, $tControlOptionalParentheses, $tSimpleControl);
$tAllKeywords  = array_merge($tKeywords, $tControl, $tDeclarations);
$tAllOperators = array_merge($tAssignmentOperators, $tArithmeticOperators, $tComparisonOperators, $tLogicalOperators, $tBitwiseOperators, $tSpecialOperators);
$tNoCompare    = array_merge($tSkip, $tComments);
