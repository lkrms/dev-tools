<?php

class CodeBlock
{
    public $Type;

    public $TypeName;

    public $Code;

    public $Line;

    public $Indent;

    /**
     * @var CodeBlock
     */
    public $PreviousBlock;

    /**
     * @var CodeBlock
     */
    public $NextBlock;

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

    public function __construct($type, $code, $line, $indent, $previous)
    {
        $this->Type           = $type;
        $this->Code           = $code;
        $this->Line           = $line;
        $this->Indent         = $indent;
        $this->PreviousBlock  = $previous;

        if (PRETTY_DEBUG_MODE && is_int($type))
        {
            $this->TypeName = token_name($type);
        }
    }

    public function Prepare($prev)
    {
        if ($this->BlankLineBefore)
        {
            $this->LineBefore   = false;
            $this->SpaceBefore  = false;

            if ( ! is_null($prev))
            {
                $prev->SpaceAfter      = false;
                $prev->LineAfter       = false;
                $prev->BlankLineAfter  = false;
            }
        }
        elseif ($this->LineBefore)
        {
            $this->SpaceBefore = false;

            if ( ! is_null($prev))
            {
                if ($prev->BlankLineAfter)
                {
                    $this->LineBefore = false;
                }
                else
                {
                    $prev->SpaceAfter  = false;
                    $prev->LineAfter   = false;
                }
            }
        }
        elseif ($this->SpaceBefore)
        {
            if ( ! is_null($prev))
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
            $this->LineAfter   = false;
            $this->SpaceAfter  = false;
        }
        elseif ($this->LineAfter)
        {
            $this->SpaceAfter = false;
        }
    }

    public function GetCode()
    {
        global $tComments;
        $prefix  = "";
        $suffix  = "";

        if ($this->BlankLineBefore)
        {
            $prefix .= PRETTY_EOL . PRETTY_EOL . str_repeat(PRETTY_TAB, $this->Indent - $this->DeIndent);
        }
        elseif ($this->LineBefore)
        {
            $prefix .= PRETTY_EOL . str_repeat(PRETTY_TAB, $this->Indent - $this->DeIndent);
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
            $suffix .= PRETTY_EOL . PRETTY_EOL . str_repeat(PRETTY_TAB, $this->Indent - $this->DeIndent);
        }
        elseif ($this->LineAfter)
        {
            $suffix .= PRETTY_EOL . str_repeat(PRETTY_TAB, $this->Indent - $this->DeIndent);
        }
        elseif ($this->SpaceAfter)
        {
            $suffix .= " ";
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

            $code = implode(PRETTY_EOL . str_repeat(PRETTY_TAB, $this->Indent - $this->DeIndent), $lines);
        }

        return $prefix . $code . $suffix;
    }
}

function PurgeTokens($tokens, array $toPurge, $removeLineNumbers = true)
{
    $purged  = array();
    $line    = 1;

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
            $type   = $code = $token;
            $token  = array($type, $code);

            if ( ! $removeLineNumbers)
            {
                $token[] = $line;
            }
        }

        if ( ! in_array($type, $toPurge))
        {
            $purged[] = $token;
        }

        $line += substr_count($token[1], PRETTY_EOL);
    }

    return $purged;
}

function CreateSummary($tokens, $withLines = false)
{
    $summary = "";

    foreach ($tokens as $token)
    {
        $line = "";

        if (is_array($token))
        {
            $type  = is_int($token[0]) ? token_name($token[0]) : "";
            $code  = $token[1];

            if ($withLines && isset($token[2]))
            {
                $line = " [{$token[2]}]";
            }
        }
        else
        {
            $type  = "";
            $code  = $token;
        }

        $summary .= "$type: $code$line" . PRETTY_EOL;
    }

    return $summary;
}

// PRETTY_NESTED_ARRAYS,0

?>