<?php

function BuildOutput($json, & $output, $indent = 0, $lastWasBlock = false)
{
    if ($isObject = is_object($json))
    {
        $openWith   = "{";
        $closeWith  = "}";
    }
    elseif (is_array($json))
    {
        $openWith   = "[";
        $closeWith  = "]";
    }
    else
    {
        $append = json_encode($json);

        if (is_string($json) && PRETTY_UNESCAPE_SLASHES)
        {
            $append = str_replace("\\/", "/", $append);
        }

        $output .= $append;

        return false;
    }

    $newLine   = PRETTY_EOL . str_repeat(PRETTY_TAB, $indent + 1);
    $newLine2  = PRETTY_EOL . str_repeat(PRETTY_TAB, $indent);

    // i.e. if this isn't the opening line
    if ($indent)
    {
        $output = rtrim($output);

        if ( ! $lastWasBlock)
        {
            $output .= $newLine2;
        }
        else
        {
            $output .= " ";
        }
    }

    $output .= $openWith . $newLine;
    $i       = 0;
    $c       = count((array)$json);
    $lwb     = false;

    foreach ($json as $key => $val)
    {
        $output .= $isObject ? json_encode($key) . ": " : "";
        $lwb     = BuildOutput($val, $output, $indent + 1, $lwb && ! $isObject);

        if ($i < $c - 1)
        {
            $output .= "," . $newLine;
        }

        $i++;
    }

    $output = rtrim($output) . $newLine2 . $closeWith;

    return true;
}

?>