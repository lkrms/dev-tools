<?php

/**
 * PrettyPhp: Just another PHP beautifier.
 * Copyright (c) 2012-2013 Luke Arms
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// load libraries and data
require_once (dirname(__FILE__) . "/pretty_functions.php");
require_once (dirname(__FILE__) . "/pretty_tokens.php");

// will be true if we're running on the command line
$onCli = false;

// used to detect line endings below
$lineEndings = array("\r\n", "\n\r", "\n", "\r", );

if (php_sapi_name() == "cli")
{
    $onCli = true;

    if ($argc != 2 || ! file_exists($srcFile = $argv[1]))
    {
        echo "Usage: php pretty.php <source file>";
        exit (1);
    }

    // figure out the source file's line endings
    $handle = @fopen($srcFile, "r");

    if ( ! $handle)
    {
        echo "Error: unable to read $srcFile.";
        exit (1);
    }

    $line = fgets($handle);
    fclose($handle);

    if ($line === false)
    {
        echo "Error: unable to read $srcFile.";
        exit (1);
    }

    foreach ($lineEndings as $ending)
    {
        if (substr($line, - strlen($ending)) == $ending)
        {
            define("PRETTY_EOL", $ending);

            break;
        }
    }

    if ( ! defined("PRETTY_EOL"))
    {
        echo "Error: unable to determine line ending type for $srcFile.";
        exit (1);
    }

    // pull in the source code
    $source = file_get_contents($srcFile);

    if ($source === false)
    {
        echo "Error: unable to read $srcFile.";
        exit (1);
    }
}
else
{
    $ending = "\r\n";

    if (isset($_POST["code"]))
    {
        $source = $_POST["code"];

        foreach ($lineEndings as $end)
        {
            if (strpos($source, $end) !== false)
            {
                $ending = $end;

                break;
            }
        }
    }
    else
    {
        $source = "<?php\r\n// Paste your code here and click Beautify. It won't be stored anywhere. ?>";
    }

    define("PRETTY_EOL", $ending);
}

// load any file-specific settings
$lines = explode(PRETTY_EOL, $source);

foreach ($lines as $line)
{
    $line = trim($line);

    if (substr($line, 0, 10) == "// PRETTY_" && strpos($line, ",") !== false)
    {
        $line                = substr($line, 3);
        list ($const, $val)  = explode(",", $line, 2);

        switch ($const)
        {
            case "PRETTY_CREATE_BACKUPS":
            case "PRETTY_CREATE_MANY_BACKUPS":
            case "PRETTY_LINE_BEFORE_BRACE":
            case "PRETTY_NESTED_ARRAYS":
            case "PRETTY_INDENT_NESTED_ARRAYS":
            case "PRETTY_SPACE_BEFORE_SEMICOLON":
            case "PRETTY_SPACE_BEFORE_FOR_SEMICOLON":
            case "PRETTY_SPACE_BEFORE_PARENTHESES":
            case "PRETTY_SPACE_INSIDE_PARENTHESES":
            case "PRETTY_SPACE_BEFORE_BRACKETS":
            case "PRETTY_SPACE_INSIDE_BRACKETS":
            case "PRETTY_SPACE_BEFORE_COLON":
            case "PRETTY_ALIGN":
            case "PRETTY_DEBUG_MODE":

                @define($const, (bool)$val);

                break;

            case "PRETTY_TAB":

                @define($const, substr($val, 1, - 1));

                break;

            case "PRETTY_ALIGN_MIN_ROWS":
            case "PRETTY_ALIGN_RANGE":

                @define($const, (int)$val);

                break;
        }
    }
}

// set any pending constants to their default values
require_once (dirname(__FILE__) . "/pretty_config.php");

// parse the code into PHP tokens
$tokens = PurgeTokens(token_get_all($source), $tSkip, false);

// work the magic
$blocks                            = array();
$indent                            = 0;
$arrayCount                        = 0;
$arrayParenthesesCount             = array();
$arrayStarted                      = -2;
$arrayStartIndent                  = 0;
$forSemicolons                     = 0;
$switchIndents                     = array();
$doIndents                         = array();
$altIndents                        = array();
$curlyOpenCount                    = 0;
$declareActive                     = false;
$blankAfterSemicolon               = false;
$blankAfterSemicolonParentheses    = 0;
$blankAfterSemicolonNoParentheses  = false;
$indentAfterParentheses            = false;
$indentOptionalParentheses         = false;
$indentWithoutParentheses          = false;
$indentParenthesesCount            = 0;
$tempIndents                       = array();
$lastTempIndentEnded               = -2;
$lastTempIndents                   = array();
$pendingIndent                     = 0;
$pendingLineBefore                 = false;
$assignments                       = array();
$noCommentPin                      = array("}", T_CLOSE_TAG);
$indentWithoutTerminators          = array(";", "{");
$indentOptionalTerminators         = array(";", "{", "(");
$compactTags                       = false;
$pendingEndCompactTags             = false;

// if present before "=" on any given line, no assignment alignment will occur
$noAssignment = array_merge($tAssignmentOperators, $tControl, $tDeclarations);

for ($i = 0; $i < count($tokens); $i++)
{
    $token          = $tokens[$i];
    $type           = $token[0];
    $code           = $token[1];
    $line           = $token[2];
    $indent        += $pendingIndent;
    $pendingIndent  = 0;

    if (in_array($type, $tTrimLeft))
    {
        $code = ltrim($code);
    }
    elseif (in_array($type, $tTrimRight))
    {
        $code = rtrim($code);
    }
    elseif ( ! in_array($type, $tNoTrim))
    {
        $code = trim($code);
    }

    $block                              = new CodeBlock($type, $code, $line, $indent);
    $block->DeIndent                    = ($arrayCount && ! PRETTY_INDENT_NESTED_ARRAYS) ? $arrayStartIndent : 0;
    $blocks[$i]                         = $block;
    $block->LineBefore                  = $pendingLineBefore;
    $pendingLineBefore                  = false;
    $oldBlankAfterSemicolonParentheses  = $blankAfterSemicolonParentheses;

    if ($blankAfterSemicolon && ! $blankAfterSemicolonNoParentheses && $type == "(")
    {
        $blankAfterSemicolonParentheses++;
    }
    elseif ($blankAfterSemicolonParentheses && $type == ")")
    {
        $blankAfterSemicolonParentheses--;

        if ( ! $blankAfterSemicolonParentheses)
        {
            $blankAfterSemicolonNoParentheses = true;
        }
    }

    $blankAfterSemicolon = $blankAfterSemicolon && ($type == ";" || $blankAfterSemicolonParentheses || $oldBlankAfterSemicolonParentheses);

    if ( ! $blankAfterSemicolon)
    {
        $blankAfterSemicolonParentheses    = 0;
        $blankAfterSemicolonNoParentheses  = false;
    }

    $colonProcessed = false;

    // handle this case: function myFunction (array $myArray)
    if ($i >= 1 && $blocks[$i - 1]->Type == T_ARRAY && $type != "(")
    {
        // reverse everything done to open the array that isn't actually an array
        $blocks[$i - 1]->SpaceAfter = true;

        if (PRETTY_NESTED_ARRAYS)
        {
            $arrayCount--;
            $arrayStarted = -2;
            array_pop($arrayParenthesesCount);
        }
    }

    if (($indentWithoutParentheses && ! in_array($type, $indentWithoutTerminators)) || ($indentOptionalParentheses && ! in_array($type, $indentOptionalTerminators)))
    {
        $block->Indent++;
        $indent++;

        // allow for "if ($something): doSomething(); endif;" syntax
        if ($type == ":")
        {
            $block->SpaceBefore  = PRETTY_SPACE_BEFORE_COLON;
            $block->LineAfter    = ! $compactTags;
            $block->SpaceAfter   = $compactTags;
            array_push($altIndents, $indent);
            $colonProcessed = true;
        }
        else
        {
            $block->LineBefore = true;
            array_push($tempIndents, $indent);
        }

        $indentWithoutParentheses   = false;
        $indentOptionalParentheses  = false;
    }

    // keep single-line PHP blocks compact, e.g. in templates
    if ($i >= 1 && in_array($blocks[$i - 1]->Type, array(T_OPEN_TAG, T_OPEN_TAG_WITH_ECHO)) && $block->Line == $blocks[$i - 1]->Line)
    {
        $blocks[$i - 1]->BlankLineAfter  = false;
        $blocks[$i - 1]->LineAfter       = false;
        $blocks[$i - 1]->SpaceAfter      = true;
        $compactTags                     = true;
        $pendingEndCompactTags           = false;
    }

    if ($pendingEndCompactTags && $type != T_CLOSE_TAG)
    {
        $compactTags            = false;
        $pendingEndCompactTags  = false;
    }

    switch ($type)
    {
        // under no circumstances are we allowed to change non-PHP code
        case T_INLINE_HTML:

            break;

        // <?php
        case T_OPEN_TAG:
        case T_OPEN_TAG_WITH_ECHO:

            $block->BlankLineAfter = true;

            break;

        /* ?> */
        case T_CLOSE_TAG:

            if ($compactTags)
            {
                $blocks[$i - 1]->BlankLineAfter  = false;
                $blocks[$i - 1]->LineAfter       = false;
                $blocks[$i - 1]->SpaceAfter      = true;
                $compactTags                     = false;
            }
            else
            {
                $block->BlankLineBefore  = true;
                $block->DeIndent         = $block->Indent;
            }

            break;

        case ";":

            // if anyone can find a way to legally add more than two semicolons inside a "for" iterator, I'm all ears
            if ($forSemicolons)
            {
                $block->SpaceAfter   = true;
                $block->SpaceBefore  = PRETTY_SPACE_BEFORE_FOR_SEMICOLON;
                $forSemicolons--;

                break;
            }

            $block->LineAfter       = true;
            $lastTempIndents        = $tempIndents;
            $pendingEndCompactTags  = true;

            while ($tempIndents)
            {
                if (($t = array_pop($tempIndents)) == $indent)
                {
                    $block->Indent--;
                    $indent--;
                    $lastTempIndentEnded = $i;
                }
                else
                {
                    array_push($tempIndents, $t);

                    break;
                }
            }

            $indentAfterParentheses = $indentOptionalParentheses = $indentWithoutParentheses = false;

            // add or remove spaces before, without breaking heredoc syntax
            if (PRETTY_SPACE_BEFORE_SEMICOLON && ! ($i >= 1 && $blocks[$i - 1]->Type == T_END_HEREDOC))
            {
                $block->SpaceBefore = true;
            }
            elseif ($i >= 1)
            {
                $blocks[$i - 1]->SpaceAfter = false;
            }

            if ($blankAfterSemicolon)
            {
                $block->BlankLineAfter             = true;
                $blankAfterSemicolon               = false;
                $blankAfterSemicolonParentheses    = 0;
                $blankAfterSemicolonNoParentheses  = false;
            }

            break;

        case ":":

            if ($colonProcessed)
            {
                break;
            }

            // switch related?
            if (($i >= 2 && $blocks[$i - 2]->Type == T_CASE) || ($i >= 1 && $blocks[$i - 1]->Type == T_DEFAULT) || ($i >= 4 && $blocks[$i - 4]->Type == T_CASE && $blocks[$i - 2]->Type == T_DOUBLE_COLON))
            {
                $block->BlankLineAfter  = ! $compactTags;
                $block->SpaceAfter      = $compactTags;
            }
            else
            {
                $block->SpaceBefore  = true;
                $block->SpaceAfter   = true;
            }

            break;

        case T_CURLY_OPEN:
        case T_DOLLAR_OPEN_CURLY_BRACES:

            // turn off normal handling of curly braces if we encounter them inside a string
            $curlyOpenCount++;

            break;

        case "{":

            if ($curlyOpenCount)
            {
                $curlyOpenCount++;

                break;
            }

            $indentAfterParentheses = $indentOptionalParentheses = $indentWithoutParentheses = false;

            if ( ! PRETTY_LINE_BEFORE_BRACE)
            {
                $block->SpaceBefore     = true;
                $block->BlankLineAfter  = ! $compactTags;
                $block->SpaceAfter      = $compactTags;
                $block->Indent++;
                $indent++;
            }
            else
            {
                $block->LineBefore   = ! $compactTags;
                $block->SpaceBefore  = $compactTags;
                $pendingLineBefore   = ! $compactTags;
                $block->SpaceAfter   = $compactTags;
                $pendingIndent++;
                unset($s);

                if ($switchIndents && ($s = array_pop($switchIndents)) == $indent)
                {
                    $block->Indent--;
                }

                if (isset($s))
                {
                    array_push($switchIndents, $s);
                }
            }

            break;

        case "}":

            if ($curlyOpenCount)
            {
                $curlyOpenCount--;

                break;
            }

            $block->BlankLineAfter = true;

            if ( ! PRETTY_LINE_BEFORE_BRACE)
            {
                $block->BlankLineBefore = true;
            }
            else
            {
                if ($i >= 1)
                {
                    $blocks[$i - 1]->BlankLineAfter = false;
                }

                $block->LineBefore = true;
            }

            $block->Indent--;
            $indent--;
            $lastTempIndents        = $tempIndents;
            $pendingEndCompactTags  = true;

            while ($tempIndents)
            {
                if (($t = array_pop($tempIndents)) == $indent + $pendingIndent)
                {
                    $block->BlankLineBefore  = false;
                    $block->BlankLineAfter   = false;
                    $block->LineBefore       = true;
                    $pendingLineBefore       = true;
                    $pendingIndent          -= 1;
                    $lastTempIndentEnded     = $i;
                }
                else
                {
                    array_push($tempIndents, $t);

                    break;
                }
            }

            // check if this is the closing brace for a recent switch
            unset($s);

            if ($switchIndents && ($s = array_pop($switchIndents)) == $indent)
            {
                $block->Indent--;
                $indent--;
            }
            elseif (isset($s))
            {
                // if not, put it back for a future check
                array_push($switchIndents, $s);
            }

            break;

        case T_ARRAY:

            $block->SpaceBefore = true;

            if (PRETTY_NESTED_ARRAYS)
            {
                // note our current indent level if this is the outmost array
                if ( ! $arrayCount++)
                {
                    $arrayStartIndent = $indent;
                }

                $arrayStarted = $i;
                array_push($arrayParenthesesCount, 0);
            }

            break;

        case "(":

            if ($curlyOpenCount)
            {
                break;
            }

            if ($arrayCount)
            {
                if ($arrayStarted == $i - 1)
                {
                    $block->LineAfter  = ! $compactTags;
                    $block->DeIndent   = ! PRETTY_INDENT_NESTED_ARRAYS ? $arrayStartIndent : 0;
                    $block->Indent++;
                    $indent++;
                }
                else
                {
                    array_push($arrayParenthesesCount, array_pop($arrayParenthesesCount) + 1);
                }
            }
            elseif ($indentOptionalParentheses)
            {
                $indentAfterParentheses     = true;
                $indentOptionalParentheses  = false;
                $indentParenthesesCount     = 1;
            }
            elseif ($indentAfterParentheses)
            {
                $indentParenthesesCount++;
            }

            if ( ! $declareActive && PRETTY_SPACE_BEFORE_PARENTHESES)
            {
                $block->SpaceBefore = true;
            }

            if ( ! $declareActive && PRETTY_SPACE_INSIDE_PARENTHESES)
            {
                $block->SpaceAfter = true;
            }

            break;

        case ")":

            if ($curlyOpenCount)
            {
                break;
            }

            $requestBlank = false;

            if ($arrayCount)
            {
                // yes, this is meant to be an assignment
                if ( ! ($c = array_pop($arrayParenthesesCount)))
                {
                    $block->LineBefore = ! $compactTags;
                    $block->Indent--;
                    $indent--;
                    $arrayCount--;
                    $requestBlank = true;
                }
                else
                {
                    array_push($arrayParenthesesCount, --$c);
                }
            }
            elseif ($indentAfterParentheses)
            {
                if ( ! --$indentParenthesesCount)
                {
                    $indentAfterParentheses    = false;
                    $indentWithoutParentheses  = true;
                }
            }

            if ( ! $declareActive && PRETTY_SPACE_INSIDE_PARENTHESES)
            {
                $block->SpaceBefore = true;
            }

            $declareActive = false;

            // empty arrays, calls, etc. should appear as "()"
            if ($i >= 1 && $blocks[$i - 1]->Type == "(")
            {
                $block->LineBefore           = false;
                $block->SpaceBefore          = false;
                $blocks[$i - 1]->LineAfter   = false;
                $blocks[$i - 1]->SpaceAfter  = false;
            }
            elseif ($requestBlank)
            {
                $blankAfterSemicolon               = true;
                $blankAfterSemicolonNoParentheses  = true;
            }

            break;

        case "[":

            if ($curlyOpenCount)
            {
                break;
            }

            // could be a PHP 5.4 array
            if ($i >= 1 && ! in_array($blocks[$i - 1]->Type, array(T_VARIABLE, ")", "]")))
            {
                $block->SpaceBefore = true;

                if (PRETTY_NESTED_ARRAYS)
                {
                    // note our current indent level if this is the outmost array
                    if ( ! $arrayCount++)
                    {
                        $arrayStartIndent = $indent;
                    }

                    array_push($arrayParenthesesCount, 0);
                    $block->LineAfter  = ! $compactTags;
                    $block->DeIndent   = ! PRETTY_INDENT_NESTED_ARRAYS ? $arrayStartIndent : 0;
                    $block->Indent++;
                    $indent++;
                }
            }
            else
            {
                if ($arrayCount)
                {
                    array_push($arrayParenthesesCount, array_pop($arrayParenthesesCount) + 1);
                }

                if (PRETTY_SPACE_BEFORE_BRACKETS)
                {
                    $block->SpaceBefore = true;
                }

                if (PRETTY_SPACE_INSIDE_BRACKETS)
                {
                    $block->SpaceAfter = true;
                }
            }

            break;

        case "]":

            if ($curlyOpenCount)
            {
                break;
            }

            $requestBlank = false;

            // PHP 5.4 array?
            if ($arrayCount)
            {
                // yes, this is meant to be an assignment
                if ( ! ($c = array_pop($arrayParenthesesCount)))
                {
                    $block->LineBefore = ! $compactTags;
                    $block->Indent--;
                    $indent--;
                    $arrayCount--;
                    $requestBlank = true;
                }
                else
                {
                    array_push($arrayParenthesesCount, --$c);
                }
            }
            else
            {
                if (PRETTY_SPACE_INSIDE_BRACKETS)
                {
                    $block->SpaceBefore = true;
                }
            }

            // ensure empty brackets appear as "[]"
            if ($i >= 1 && $blocks[$i - 1]->Type == "[")
            {
                $block->SpaceBefore          = false;
                $block->LineBefore           = false;
                $blocks[$i - 1]->SpaceAfter  = false;
                $blocks[$i - 1]->LineAfter   = false;
            }
            elseif ($requestBlank)
            {
                $blankAfterSemicolon               = true;
                $blankAfterSemicolonNoParentheses  = true;
            }

            break;

        case ",":

            if ($arrayCount)
            {
                $c = array_pop($arrayParenthesesCount);

                if ($c || $compactTags)
                {
                    $block->SpaceAfter = true;
                }
                else
                {
                    $block->LineAfter = true;
                }

                array_push($arrayParenthesesCount, $c);
            }
            else
            {
                $block->SpaceAfter = true;
            }

            break;

        case T_SWITCH:

            $block->BlankLineBefore  = ! $compactTags;
            $block->SpaceBefore      = $compactTags;
            $block->SpaceAfter       = true;

            // this is how we handle the weirdness of switch structures
            array_push($switchIndents, ++$indent);

            break;

        case T_CASE:
        case T_DEFAULT:

            $block->BlankLineBefore  = ! $compactTags;
            $block->SpaceBefore      = $compactTags;
            $block->SpaceAfter       = $type == T_CASE;
            $block->Indent--;

            // collapse empty lines between contiguous case/default statements
            if (($i >= 2 && $blocks[$i - 2]->Type == T_DEFAULT) || ($i >= 3 && $blocks[$i - 3]->Type == T_CASE) || ($i >= 5 && $blocks[$i - 5]->Type == T_CASE && $blocks[$i - 3]->Type == T_DOUBLE_COLON))
            {
                $block->LineBefore               = $block->BlankLineBefore;
                $block->BlankLineBefore          = false;
                $blocks[$i - 1]->BlankLineAfter  = false;
            }

            break;

        case T_COMMENT:
        case T_DOC_COMMENT:

            if ($i >= 1 && ! is_null($blocks[$i - 1]->Line) && $blocks[$i - 1]->Line == $block->Line)
            {
                $block->TabBefore                = true;
                $block->BlankLineAfter           = $blocks[$i - 1]->BlankLineAfter;
                $block->LineAfter                = $blocks[$i - 1]->LineAfter;
                $blocks[$i - 1]->BlankLineAfter  = false;
                $blocks[$i - 1]->LineAfter       = false;
            }
            else
            {
                $block->BlankLineBefore = true;
            }

            $block->LineAfter       = true;
            $pendingEndCompactTags  = true;

            break;

        case T_START_HEREDOC:

            $block->LineAfter       = true;
            $pendingEndCompactTags  = true;

            break;

        case T_END_HEREDOC:

            $block->LineBefore = true;

            break;

        case T_DECLARE:

            $declareActive = true;

            break;

        case T_HALT_COMPILER:

            $block->BlankLineBefore  = true;
            $pendingEndCompactTags   = true;

            break;

        case T_VARIABLE:

            if ($i >= 1 && $blocks[$i - 1]->Type == T_STRING && ! ($blocks[$i - 1]->SpaceAfter || $blocks[$i - 1]->LineAfter || $blocks[$i - 1]->BlankLineAfter))
            {
                $block->SpaceBefore = true;
            }

        default:

            if (in_array($type, $tControl) && ! in_array($type, $tControlOptions))
            {
                $block->BlankLineBefore  = ! $compactTags;
                $block->SpaceBefore      = $compactTags;

                if ($type == T_DO)
                {
                    array_push($doIndents, $indent);
                }
                elseif ($type == T_WHILE)
                {
                    unset($d);

                    if ($doIndents && ($d = array_pop($doIndents)) == $indent)
                    {
                        $block->BlankLineBefore  = false;
                        $block->SpaceBefore      = true;

                        if ($blocks[$i - 1]->Type == "}")
                        {
                            $blocks[$i - 1]->BlankLineAfter  = false;
                            $blocks[$i - 1]->LineAfter       = PRETTY_LINE_BEFORE_BRACE;
                        }

                        $blankAfterSemicolon = true;
                    }
                    elseif (isset($d))
                    {
                        array_push($doIndents, $d);
                    }
                }
                elseif ($type == T_FOR)
                {
                    $forSemicolons = 2;
                }
            }

            // if there's a single-line code block belonging to this control structure, it should be on its own line and indented
            if (in_array($type, $tControlNoParentheses))
            {
                $indentWithoutParentheses = true;
            }
            elseif (in_array($type, $tControlOptionalParentheses))
            {
                $indentOptionalParentheses = true;
            }
            elseif (in_array($type, $tControlWithParentheses))
            {
                $indentAfterParentheses = true;
            }

            if (in_array($type, $tDeclarations) && ! ($i >= 1 && in_array($blocks[$i - 1]->Type, $tDeclarations)) && ! ($i >= 2 && in_array($blocks[$i - 2]->Type, $tDeclarations) && $blocks[$i - 1]->Type == T_STRING))
            {
                $block->BlankLineBefore = true;
            }

            if (in_array($type, $tAllKeywords) || in_array($type, $tAllOperators))
            {
                $block->SpaceBefore = true;

                // e.g. $i = -1;
                if ( ! ($i >= 1 && in_array($type, $tArithmeticOperators) && in_array($blocks[$i - 1]->Type, $tAllOperators)))
                {
                    $block->SpaceAfter = true;
                }
            }

            // else, elseif, etc. shouldn't appear on a new line
            if (in_array($type, $tControlOptions))
            {
                $block->SpaceBefore = true;

                if ($i >= 1 && $blocks[$i - 1]->Type == "}")
                {
                    $blocks[$i - 1]->BlankLineAfter  = false;
                    $blocks[$i - 1]->LineAfter       = PRETTY_LINE_BEFORE_BRACE;
                }

                // e.g. in the absence of braces, an "else" after a nested "if" should relate to the nested "if", not an outer one;
                // also, code this ambiguous should be shot.
                if ($lastTempIndentEnded == $i - 1)
                {
                    // pow pow pow
                    if ($blocks[$i - 1]->Type == ";")
                    {
                        $indent = $block->Indent = $blocks[$i - 1]->Indent = array_pop($lastTempIndents) - 1;
                    }
                    else
                    {
                        $indent             = $block->Indent = $blocks[$i - 1]->Indent;
                        $block->LineBefore  = false;
                    }

                    $tempIndents = $lastTempIndents;
                }
            }

            if (in_array($type, $tControlOptions) || in_array($type, $tAltControl))
            {
                unset($a);

                if ($altIndents && ($a = array_pop($altIndents)) == $indent)
                {
                    $block->LineBefore               = ! $compactTags;
                    $block->SpaceBefore              = $compactTags;
                    $blocks[$i - 1]->BlankLineAfter  = false;
                    $block->Indent--;
                    $indent--;

                    if ( ! $altIndents)
                    {
                        $blankAfterSemicolon = true;
                    }
                }
                elseif (isset($a))
                {
                    array_push($altIndents, $a);
                }
            }

            if ($declareActive && $type == "=")
            {
                $block->SpaceBefore = $block->SpaceAfter = false;
            }

            break;
    }

    // pin comments to the code below them
    if ($block->BlankLineBefore && ! in_array($type, $noCommentPin))
    {
        $j = $i - 1;

        while ($j > 0 && in_array($blocks[$j]->Type, $tComments))
        {
            // retain blank lines between comment blocks of different types
            if ($j == $i - 1 && ! (in_array($type, $tComments) && ($type != $blocks[$j]->Type || substr($block->Code, 0, 2) != substr($blocks[$j]->Code, 0, 2))))
            {
                $block->BlankLineBefore = false;
            }

            $blocks[$j]->Indent    = $block->Indent;
            $blocks[$j]->DeIndent  = $block->DeIndent;
            $j--;
        }
    }

    $block->BlankLineBefore = $block->BlankLineBefore && ( ! PRETTY_LINE_BEFORE_BRACE || ! ($i >= 1 && $blocks[$i - 1]->Type == "{"));

    // keep un-braced code blocks tight
    if ($tempIndents || $altIndents)
    {
        if ($block->BlankLineBefore)
        {
            $block->BlankLineBefore  = false;
            $block->LineBefore       = true;
        }

        if ($block->BlankLineAfter)
        {
            $block->BlankLineAfter  = false;
            $block->LineAfter       = true;
        }
    }
}

$prev = null;

foreach ($blocks as $block)
{
    $block->Prepare($prev);
    $prev = $block;
}

// first pass
$output = "";

for ($i = 0; $i < count($blocks); $i++)
{
    $block = $blocks[$i];

    if (PRETTY_ALIGN)
    {
        $line  = substr_count($output, PRETTY_EOL) + 1;
        $col   = strrpos($output, PRETTY_EOL);

        if ($col === false)
        {
            $col = strlen($output);
        }
        else
        {
            $col = strlen($output) - $col - strlen(PRETTY_EOL);
        }

        $block->OutLine  = $line;
        $block->OutCol   = $col;
        $indent          = $block->Indent - $block->DeIndent;

        if ($block->Type == T_DOUBLE_ARROW || in_array($block->Type, $tAssignmentOperators))
        {
            $j         = $i - 1;
            $isAssign  = true;

            while ($j >= 0 && $blocks[$j]->OutLine == $line)
            {
                if (in_array($blocks[$j]->Type, $noAssignment))
                {
                    $isAssign = false;

                    break;
                }

                // identify the indent level of the whole assignment
                $indent = $blocks[$j]->Indent - $blocks[$j]->DeIndent;
                $j--;
            }

            if ($isAssign)
            {
                $assignments[] = array($line, $col, $i, $indent);
            }
        }
    }

    $output .= $block->GetCode();
}

if (PRETTY_ALIGN)
{
    // this forces the last assignment block to resolve
    $assignments[]  = array($line + 2);
    $startLine      = null;
    $maxCol         = 0;

    for ($j = 0; $j < count($assignments); $j++)
    {
        if (isset($assignments[$j - 1]) && $assignments[$j][0] - $assignments[$j - 1][0] == 1 && abs($assignments[$j][1] - $assignments[$j - 1][1]) <= PRETTY_ALIGN_RANGE && ! (($blocks[$assignments[$j][2]]->Type == T_DOUBLE_ARROW) xor ($blocks[$assignments[$j - 1][2]]->Type == T_DOUBLE_ARROW)) && $assignments[$j][3] == $assignments[$j - 1][3])
        {
            if (is_null($startLine))
            {
                $startLine  = $j - 1;
                $maxCol     = $assignments[$j - 1][1];
            }

            $maxCol = $maxCol < $assignments[$j][1] ? $assignments[$j][1] : $maxCol;
        }
        else
        {
            if ( ! is_null($startLine) && ($endLine = $j - 1) > $startLine && $endLine - $startLine + 1 >= PRETTY_ALIGN_MIN_ROWS)
            {
                for ($k = $startLine; $k <= $endLine; $k++)
                {
                    $block         = $blocks[$assignments[$k][2]];
                    $block->PadTo  = $maxCol - $block->OutCol + 2;
                }
            }

            $startLine = null;
        }
    }

    // second pass
    $output = "";

    foreach ($blocks as $block)
    {
        $output .= $block->GetCode();
    }
}

$error      = "";
$errFolder  = dirname(__FILE__) . "/";

// verify that we haven't changed anything irreparably. cos that would be bad.
$newPurged  = PurgeTokens($newTokens = token_get_all($output), $tNoCompare);
$oldPurged  = PurgeTokens($oldTokens = token_get_all($source), $tNoCompare);

if ($newPurged != $oldPurged)
{
    if (PRETTY_DEBUG_MODE)
    {
        file_put_contents("{$errFolder}prettySrc.err", CreateSummary($oldPurged));
        file_put_contents("{$errFolder}prettyDest.err", CreateSummary($newPurged));
        file_put_contents("{$errFolder}prettySrcLines.err", CreateSummary(PurgeTokens($oldTokens, $tNoCompare, false), true));
        file_put_contents("{$errFolder}prettyOutput.err", $output);
    }

    if ($onCli)
    {
        print "Error: unable to format $srcFile. Please check your syntax and/or file a bug report.";
        $error = true;
    }
    else
    {
        $error = "Error: unable to format your code. Please try again.";
    }
}
elseif ($onCli)
{
    if (PRETTY_CREATE_BACKUPS && rename($srcFile, $srcFile . (PRETTY_CREATE_MANY_BACKUPS ? "." . date("YmdHis") : "") . ".bak") === false)
    {
        print "Error: unable to back up $srcFile.";
        $error = true;
    }

    if (file_put_contents($srcFile, $output) === false)
    {
        print "Error: unable to write to $srcFile.";
        $error = true;
    }
}

if (PRETTY_DEBUG_MODE)
{
    if ( ! $error)
    {
        file_put_contents("{$errFolder}pretty.out", CreateSummary($tokens));
    }

    file_put_contents("{$errFolder}pretty.long.out", print_r($blocks, true));
}

if ($onCli && $error)
{
    exit (1);
}

if ($onCli)
{
    exit;
}

// PRETTY_NESTED_ARRAYS,0

?>
<html>
<head>
<title>PrettyPhp</title>
</head>
<body>
<?php

if ($error)
{
    print "<p>$error</p>";
}

?>
<form method="post" action="<?php

echo $_SERVER["REQUEST_URI"];

?>">
<textarea rows="20" cols="100" name="code"><?php

echo htmlentities($error ? $source : $output);

?></textarea><br />
<input type="submit" value="Beautify" />
</form>
</body>
</html>
