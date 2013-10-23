<?php

/**
 * PrettyJson: Just another JSON beautifier.
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

// load settings, libraries
require_once (dirname(__FILE__) . "/pretty_config.php");
require_once (dirname(__FILE__) . "/pretty_functions.php");

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

    // there's a good chance there won't be any line breaks in a JSON file
    if ( ! defined("PRETTY_EOL"))
    {
        define("PRETTY_EOL", $lineEndings[0]);
    }

    $source = file_get_contents($srcFile);

    if ($source === false)
    {
        echo "Error: unable to read $srcFile.";
        exit (1);
    }
}
else
{
    $ending = $lineEndings[0];

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
        $source = "[ \"Paste your JSON here and click Beautify. It won't be stored anywhere.\" ]";
    }

    define("PRETTY_EOL", $ending);
}

$error      = "";
$errFolder  = dirname(__FILE__) . "/";
$json       = json_decode($source);

if (json_last_error() != JSON_ERROR_NONE)
{
    if ($onCli)
    {
        print "Error: unable to decode $srcFile.";
        exit (1);
    }
    else
    {
        $error = "Error: unable to decode your JSON. Please try again.";
    }
}

if ( ! $error)
{
    $output = "";
    BuildOutput($json, $output);

    // verify that we haven't changed anything irreparably. cos that would be bad.
    $new = json_decode($output);

    if ($new != $json)
    {
        if (PRETTY_DEBUG_MODE)
        {
            file_put_contents("{$errFolder}prettyOutput.err", $output);
        }

        if ($onCli)
        {
            print "Error: unable to format $srcFile. Please check your syntax and/or file a bug report.";
            exit (1);
        }
        else
        {
            $error = "Error: unable to format your JSON. Please try again.";
        }
    }
    elseif ($onCli)
    {
        if (PRETTY_CREATE_BACKUPS && rename($srcFile, $srcFile . (PRETTY_CREATE_MANY_BACKUPS ? "." . date("YmdHis") : "") . ".bak") === false)
        {
            print "Error: unable to back up $srcFile.";
            exit (1);
        }

        if (file_put_contents($srcFile, $output) === false)
        {
            print "Error: unable to write to $srcFile.";
            exit (1);
        }
    }
}

if ($onCli)
{
    exit;
}

// PRETTY_NESTED_ARRAYS,0

?>
<html>
<head>
<title>PrettyJson</title>
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
