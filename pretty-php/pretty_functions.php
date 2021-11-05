<?php

class CodeBlock
{
    public $Type;

    public $TypeName;

    public $Code;

    public $Line;

    public $Indent;

    public $InHeredoc;

    /**
     * @var CodeBlock
     */
    public $PreviousBlock;

    /**
     * @var CodeBlock
     */
    public $NextBlock;

    public $LineDelta = 0;

    public $OutLine;

    public $OutCol;

    public $DeIndent = 0;

    public $PadTo = 0;

    public $BlankLineBefore = false;

    public $LineBefore = false;

    public $TabBefore = false;

    public $SpaceBefore = false;

    public $SpaceAfter = false;

    public $LineAfter = false;

    public $BlankLineAfter = false;

    // the following properties are used to track indentation when line breaks
    // are being preserved
    private static $DepthStack = [];

    private static $LineIndentStack = [];

    private static $LastLineIndentContext;

    public $Depth;

    public $LastDepth;

    public $LineIndent;

    public $PrevLineIndent;

    public function __construct($type, $code, $line, $indent, $inHeredoc, $previous)
    {
        $this->Type      = $type;
        $this->Code      = $code;
        $this->Line      = $line;
        $this->Indent    = $indent;
        $this->InHeredoc = $inHeredoc;

        if (PRETTY_DEBUG_MODE && is_int($type))
        {
            $this->TypeName = token_name($type);
        }

        if ($previous)
        {
            $previous->NextBlock = $this;
            $this->PreviousBlock = $previous;
            $this->LineDelta     = $line - ($previous->Line + substr_count($previous->Code, PRETTY_EOL));
        }
    }

    public function HasBlankLineAfter()
    {
        return $this->BlankLineAfter || ($this->NextBlock->BlankLineBefore ?? false);
    }

    public function HasLineAfter()
    {
        return $this->HasBlankLineAfter() || $this->LineAfter || ($this->NextBlock->LineBefore ?? false);
    }

    public function HasBlankLineBefore()
    {
        return $this->BlankLineBefore || ($this->PreviousBlock->BlankLineAfter ?? false);
    }

    public function HasLineBefore()
    {
        return $this->HasBlankLineBefore() || $this->LineBefore || ($this->PreviousBlock->LineAfter ?? false);
    }

    private function MaybePushLineIndentContext()
    {
        if ((self::$LastLineIndentContext->Indent ?? -1) < $this->Indent)
        {
            self::$LineIndentStack[]     = $this;
            self::$LastLineIndentContext = $this;
            $this->PrevLineIndent       += $this->LineIndent;
            $this->LineIndent            = 0;
        }
    }

    private function MaybePopLineIndentContext()
    {
        if ((self::$LastLineIndentContext->Indent ?? $this->Indent) > $this->Indent)
        {
            $prev                 = array_pop(self::$LineIndentStack)->PreviousBlock;
            $this->LastDepth      = $prev->LastDepth;
            $this->LineIndent     = $prev->LineIndent;
            $this->PrevLineIndent = $prev->PrevLineIndent;

            if (self::$LastLineIndentContext = array_pop(self::$LineIndentStack))
            {
                self::$LineIndentStack[] = self::$LastLineIndentContext;
            }
        }
    }

    public function Prepare($prev)
    {
        if (!PRETTY_IGNORE_LINE_BREAKS)
        {
            $this->Depth          = $prev->Depth ?? 0;
            $this->LastDepth      = $prev->LastDepth ?? 0;
            $this->LineIndent     = $prev->LineIndent ?? 0;
            $this->PrevLineIndent = $prev->PrevLineIndent ?? 0;

            $this->MaybePopLineIndentContext();

            $opener = null;

            switch ($this->Type)
            {
                case ")":
                case "]":
                case "}":

                    $this->Depth--;
                    $opener = array_pop(self::$DepthStack);

                    break;
            }

            if ($prev)
            {
                if (!$this->HasLineBefore() &&
                    (($opener && $opener->HasLineAfter()) ||
                        ($this->LineDelta &&
                            !($opener && !$opener->HasLineAfter()) &&
                            !in_array($this->Type, ["{", "}"]) &&
                            (in_array($prev->Type, $GLOBALS["tAllowLineAfter"]) ||
                                in_array($this->Type, $GLOBALS["tAllowLineBefore"])))))
                {
                    $this->LineBefore = true;

                    if ($this->Depth > $this->LastDepth)
                    {
                        $this->MaybePushLineIndentContext();
                        $this->LineIndent++;
                    }
                    else
                    {
                        $this->LineIndent -= $this->LastDepth - $this->Depth;
                    }

                    $this->LastDepth = $this->Depth;
                }
                elseif (($this->HasLineBefore() || $this->HasLineAfter()) &&
                    $this->LineIndent && $this->Depth <= $this->LastDepth)
                {
                    $this->LineIndent -= $this->LastDepth - $this->Depth;
                    $this->LastDepth   = $this->Depth;
                }

                if ($this->LineIndent <= 0)
                {
                    $this->LineIndent = 0;
                    $this->LastDepth  = 0;
                }

                // Preserve but squeeze empty lines
                if (!PRETTY_REMOVE_EMPTY_LINES &&
                    $this->HasLineBefore() && $this->LineDelta > 1 && (!in_array($prev->Type, ["(", "[", "{"])))
                {
                    $this->BlankLineBefore = true;
                }
            }

            switch ($this->Type)
            {
                case "(":
                case "[":
                case "{":
                case T_CURLY_OPEN:
                case T_DOLLAR_OPEN_CURLY_BRACES:

                    $this->Depth++;
                    array_push(self::$DepthStack, $this);

                    break;
            }
        }

        if ($this->BlankLineBefore)
        {
            $this->LineBefore  = false;
            $this->SpaceBefore = false;

            if ($prev)
            {
                $prev->SpaceAfter     = false;
                $prev->LineAfter      = false;
                $prev->BlankLineAfter = false;
            }
        }
        elseif ($this->LineBefore)
        {
            $this->SpaceBefore = false;

            if ($prev)
            {
                if ($prev->BlankLineAfter)
                {
                    $this->LineBefore = false;
                }
                else
                {
                    $prev->SpaceAfter = false;
                    $prev->LineAfter  = false;
                }
            }
        }
        elseif ($this->SpaceBefore)
        {
            if ($prev)
            {
                if ($prev->BlankLineAfter || $prev->LineAfter)
                {
                    $this->SpaceBefore = false;
                }
                else
                {
                    $prev->SpaceAfter = false;
                }
            }
        }

        if ($this->BlankLineAfter)
        {
            $this->LineAfter  = false;
            $this->SpaceAfter = false;
        }
        elseif ($this->LineAfter)
        {
            $this->SpaceAfter = false;
        }
    }

    public function GetCode()
    {
        global $tComments;
        $string   = "";
        $toEscape = "\000..\t\v\f\016..\037\177..\377\\\$\"";    # equivalent to "\x00..\x09\x0b\x0c\x0e..\x1f\x7f..\xff\\\$\""

        // retain newline escapes if they are already present
        if (preg_match("/^([^\\\\]|\\\\.)*\\\\[nr]/", $this->Code))
        {
            $toEscape .= "\r\n";
        }

        switch ($this->Type)
        {
            case T_CONSTANT_ENCAPSED_STRING:

                if (!$this->InHeredoc && ((PRETTY_DECODE_STRINGS && $this->Code[0] == "\"") || PRETTY_DOUBLE_QUOTE_STRINGS))
                {
                    eval ("\$string = {$this->Code};");
                    $this->Code = "\"" . addcslashes($string, $toEscape) . "\"";
                }

                break;

            case T_ENCAPSED_AND_WHITESPACE:

                if (!$this->InHeredoc && (PRETTY_DECODE_STRINGS || PRETTY_DOUBLE_QUOTE_STRINGS))
                {
                    eval ("\$string = \"{$this->Code}\";");
                    $this->Code = addcslashes($string, $toEscape);
                }

                break;

            case T_START_HEREDOC:

                $this->DeIndent = $this->Indent + $this->LineIndent + $this->PrevLineIndent;

                break;
        }

        $prefix = "";
        $suffix = "";

        if (!$this->InHeredoc)
        {
            if ($this->BlankLineBefore)
            {
                $prefix .= PRETTY_EOL . PRETTY_EOL . str_repeat(PRETTY_TAB, $this->Indent + $this->LineIndent + $this->PrevLineIndent - $this->DeIndent);
            }
            elseif ($this->LineBefore)
            {
                $prefix .= PRETTY_EOL . str_repeat(PRETTY_TAB, $this->Indent + $this->LineIndent + $this->PrevLineIndent - $this->DeIndent);
            }
            elseif ($this->TabBefore)
            {
                // TODO: align this to nearest tab stop
                $prefix .= PRETTY_TAB;
            }
            elseif ($this->SpaceBefore)
            {
                $prefix .= " ";
            }

            if ($this->BlankLineAfter)
            {
                $suffix .= PRETTY_EOL . PRETTY_EOL . str_repeat(PRETTY_TAB, $this->Indent + $this->LineIndent + $this->PrevLineIndent - $this->DeIndent);
            }
            elseif ($this->LineAfter)
            {
                $suffix .= PRETTY_EOL . str_repeat(PRETTY_TAB, $this->Indent + $this->LineIndent + $this->PrevLineIndent - $this->DeIndent);
            }
            elseif ($this->SpaceAfter)
            {
                $suffix .= " ";
            }
        }

        $code = str_pad($this->Code, $this->PadTo, " ", STR_PAD_LEFT);

        // comments might be multi-line, and should be tabulated as such
        if (in_array($this->Type, $tComments))
        {
            $lines = explode(PRETTY_EOL, $this->Code);

            for ($l = 0; $l < count($lines); $l++)
            {
                $line = trim($lines[$l]);

                if ($this->Type == T_DOC_COMMENT && $l)
                {
                    $line = " " . ($l < count($lines) - 1 && substr($line, 0, 1) != "*" ? "* " : "") . $line;
                }

                $lines[$l] = $line;
            }

            $code = implode(PRETTY_EOL . str_repeat(PRETTY_TAB, $this->Indent + $this->LineIndent + $this->PrevLineIndent - $this->DeIndent), $lines);
        }

        return $prefix . $code . $suffix;
    }
}

function ApplyConfig($option, $value)
{
    switch ($option)
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
        case "PRETTY_DOUBLE_QUOTE_STRINGS":
        case "PRETTY_DECODE_STRINGS":
        case "PRETTY_IGNORE_LINE_BREAKS":
        case "PRETTY_REMOVE_EMPTY_LINES":

            @define($option, (bool)$value);

            break;

        case "PRETTY_TAB":

            if (preg_match("/^\".*\"\$/", $value))
            {
                @define($option, substr($value, 1, -1));
            }
            else
            {
                @define($option, $value);
            }

            break;

        case "PRETTY_ALIGN_MIN_ROWS":
        case "PRETTY_ALIGN_RANGE":

            @define($option, (int)$value);

            break;
    }
}

function PurgeTokens($tokens, array $toPurge, $removeLineNumbers = true)
{
    $purged = array();
    $line   = 1;

    foreach ($tokens as $token)
    {
        if (is_array($token))
        {
            $type = $token[0];

            if ($removeLineNumbers)
            {
                unset($token[2]);
            }
            else
            {
                $line = $token[2];
            }
        }
        else
        {
            $type  = $code = $token;
            $token = array($type, $code);

            if (!$removeLineNumbers)
            {
                $token[] = $line;
            }
        }

        if (!in_array($type, $toPurge))
        {
            $purged[] = $token;
        }

        $line += substr_count($token[1], PRETTY_EOL);
    }

    return $purged;
}

function AnnotateTokens($tokens)
{
    foreach ($tokens as & $token)
    {
        if (is_array($token))
        {
            $token[] = is_int($token[0]) ? token_name($token[0]) : $token[0];
        }
    }

    return $tokens;
}

function AnnotateBlocks($blocks)
{
    foreach ($blocks as & $block)
    {
        $block = clone $block;
        unset($block->PreviousBlock);
        unset($block->NextBlock);
    }

    return $blocks;
}

function CreateSummary($tokens, $withLines = false)
{
    $summary = "";

    foreach ($tokens as $token)
    {
        $line = "";

        if (is_array($token))
        {
            $type = is_int($token[0]) ? token_name($token[0]) : "";
            $code = $token[1];

            if ($withLines && isset($token[2]))
            {
                $line = " [{$token[2]}]";
            }
        }
        else
        {
            $type = "";
            $code = $token;
        }

        $summary .= "$type: $code$line" . PRETTY_EOL;
    }

    return $summary;
}

// PRETTY_NESTED_ARRAYS,0
// PRETTY_IGNORE_LINE_BREAKS,0
