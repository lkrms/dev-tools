#!/usr/bin/php
<?php

if (PHP_SAPI !== 'cli')
{
    throw new Exception('Error: this script must be run from the command line.');
}

function find_files($parent)
{
    global $files;

    // an equivalent to GNU "find" would be nice, but we're stuck with more rudimentary methods
    $paths = scandir($parent);

    foreach ($paths as $path)
    {
        if (in_array($path, array('.', '..')))
        {
            continue;
        }

        $fullPath = $parent . DIRECTORY_SEPARATOR . $path;

        if (is_dir($fullPath))
        {
            if (NFO_RECURSIVE)
            {
                find_files($fullPath);
            }
        }
        elseif (is_file($fullPath))
        {
            // ignore hidden files
            if (preg_match('/^[^.].*\.(m4v)$/i', $path))
            {
                $files[] = realpath($fullPath);
            }
        }
    }
}

$options     = getopt('fr', array('force', 'recursive'), $optind);
$optionKeys  = array_keys($options);
$paths       = array_slice($argv, $optind);

if ( ! $paths)
{
    echo 'Usage: ' . basename(__FILE__) . ' [-f|--force] [-r|--recursive] file|folder[, file|folder...]' . PHP_EOL;
    exit (1);
}

if (in_array('f', $optionKeys) || in_array('force', $optionKeys))
{
    define('NFO_OVERWRITE', true);
}
else
{
    define('NFO_OVERWRITE', false);
}

if (in_array('r', $optionKeys) || in_array('recursive', $optionKeys))
{
    define('NFO_RECURSIVE', true);
}
else
{
    define('NFO_RECURSIVE', false);
}

$files = array();

foreach ($paths as $path)
{
    if (is_dir($path))
    {
        $path = dirname($path) . DIRECTORY_SEPARATOR . basename($path);
        find_files($path);
    }
    elseif (is_file($path))
    {
        $files[] = realpath($path);
    }
    else
    {
        echo "Error: $path is not a file or folder." . PHP_EOL;
        exit (1);
    }
}

foreach ($files as $sourceFile)
{
    $nfoFile = preg_replace('/\.[0-9a-z]+$/i', '.nfo', $sourceFile);

    if (file_exists($nfoFile) && ! NFO_OVERWRITE)
    {
        continue;
    }

    exec('mediainfo --Output=XML ' . escapeshellarg($sourceFile), $xml, $result);

    if ($result)
    {
        echo 'Error calling mediainfo. Is it installed?' . PHP_EOL;
        exit (2);
    }

    $xml   = implode('', $xml);
    $info  = new SimpleXMLElement($xml);

    if (empty($info->media [0]->track [0]->VideoCount) || ! (int)$info->media [0]->track [0]->VideoCount)
    {
        echo 'Skipping (not a video file): ' . $sourceFile . PHP_EOL;

        continue;
    }

    // round duration up
    $duration  = (int)ceil(((float)$info->media [0]->track [0]->Duration) / 60);
    $isTvShow  = (string)$info->media [0]->track [0]->ContentType == 'TV Show';
}

// PRETTY_NESTED_ARRAYS,0
