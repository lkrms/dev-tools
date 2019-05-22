<?php

function GetBytes($val)
{
    $val   = trim($val);
    $last  = strtolower($val[strlen($val) - 1]);
    $val   = (int)$val;

    switch ($last)
    {
        case 'g':

            $val *= 1024;

        case 'm':

            $val *= 1024;

        case 'k':

            $val *= 1024;
    }

    return $val;
}

$isCli = (PHP_SAPI == 'cli');

if ($isCli)
{
    if ($argc > 1)
    {
        $filename = $argv[1];

        if ( ! file_exists($filename))
        {
            throw new Exception("File not found: $argv[1]");
        }
    }
    else
    {
        throw new Exception('No ZIP filename given.');
    }
}
else
{
    if ($_SERVER['REQUEST_METHOD'] == 'POST')
    {
        if ( ! isset($_FILES['zipFile']))
        {
            throw new Exception('No upload received: check post_max_size and upload_max_filesize.');
        }

        if (is_uploaded_file($_FILES['zipFile']['tmp_name']))
        {
            $filename = $_FILES['zipFile']['tmp_name'];
        }
        else
        {
            throw new Exception('Error with upload.');
        }
    }
    else
    {
?>
<!DOCTYPE html>
<html>

<head>
    <title>Flatten ZIP</title>
    <meta charset="UTF-8">
</head>

<body>
    <form enctype="multipart/form-data" action="<?php  echo $_SERVER['REQUEST_URI']; ?>" method="POST">
        <input type="hidden" name="MAX_FILE_SIZE" value="<?php  echo GetBytes(ini_get('upload_max_filesize')); ?>">
        <input name="zipFile" type="file"><br>
        <input type="submit" value="Flatten">
    </form>
</body>

</html>
    <?php

        exit;
    }
}

// make it Thursday
$now = time();

while (date('w', $now) != '4')
{
    $now += 60 * 60 * 24;
}

$prefix = date('ymd', $now);

// TODO: wrap this up in a try/catch?
// open it
$zip = new ZipArchive();

if ($zip->open($filename) !== true)
{
    throw new Exception('Error opening ZIP archive.');
}

// get all file/directory names inside
$names = array();

for ($i = 0; $i < $zip->numFiles; $i++)
{
    $s = $zip->statIndex($i);

    if ($s === false)
    {
        throw new Exception('Error retrieving information from ZIP archive.');
    }

    $names[] = $s['name'];
}

// delete cruft we don't want to keep
$delete = preg_grep('/((^|\/)\..*|thumbs.db$|^__MACOSX)/i', $names);

foreach ($delete as $fn)
{
    if ($zip->deleteName($fn) === false)
    {
        throw new Exception('Error deleting file from ZIP archive.');
    }

    if ($isCli)
    {
        echo "Deleted from archive: $fn\n";
    }
}

// move things up until we have multiple subdirectories at the top (or just files)
$names = array_diff($names, $delete);

while (count($singleParent = preg_grep('/^[^\/]+\/$/', $names)) == 1)
{
    $strip     = strlen($singleParent[0]);
    $newNames  = array();

    foreach ($names as $oldName)
    {
        $newName = substr($oldName, $strip);

        if (empty($newName))
        {
            if ($zip->deleteName($oldName) === false)
            {
                throw new Exception('Error deleting directory from ZIP archive.');
            }

            if ($isCli)
            {
                echo "Deleted from archive: $oldName\n";
            }

            continue;
        }

        if ($zip->renameName($oldName, $newName) === false)
        {
            throw new Exception('Error renaming file in ZIP archive.');
        }

        $newNames[] = $newName;

        if ($isCli)
        {
            echo "Renamed in archive: \"{$oldName}\" to \"{$newName}\"\n";
        }
    }

    $names = $newNames;
}

// TODO: customisable regex with optional prefix callback and subfolder
$toFlatten  = preg_grep('/.*\.(jpe?g|png)$/i', $names);
$flattened  = array();

foreach ($toFlatten as $oldName)
{
    $newName = explode('/', $oldName);

    if ( ! empty($prefix))
    {
        array_unshift($newName, $prefix);
    }

    $newName = implode('-', $newName);

    if ($zip->renameName($oldName, $newName) === false)
    {
        throw new Exception('Error renaming file in ZIP archive.');
    }

    if ($isCli)
    {
        echo "Renamed in archive: \"{$oldName}\" to \"{$newName}\"\n";
    }

    $flattened[] = $newName;
}

$names = array_merge(array_diff($names, $toFlatten), $flattened);

// find and delete empty directories
$dirs = preg_grep('/.+\/$/i', $names);

// longest to shortest
usort($dirs,

function ($a, $b)
{
    $al  = strlen($a);
    $bl  = strlen($b);

    if ($al == $bl)
    {
        return 0;
    }

    return $al < $bl ? 1 : - 1;
}

);

foreach ($dirs as $dir)
{
    $matching = array_filter($names,

    function ($n) use ($dir)
    {
        if (strpos($n, $dir) === 0)
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    );

    // it's just us -- so delete away
    if (count($matching) == 1)
    {
        if ($zip->deleteName($dir) === false)
        {
            throw new Exception('Error deleting directory from ZIP archive.');
        }

        if ($isCli)
        {
            echo "Deleted from archive: $dir\n";
        }

        $names = array_diff($names, [
            $dir
        ]);
    }
}

// save everything
if ($zip->close() === false)
{
    throw new Exception('Error saving changes to ZIP archive.');
}

if ( ! $isCli)
{
    header('Content-Type: application/zip');
    header('Content-Disposition: attachment; filename="' . rawurlencode('flattened-' . basename($_FILES['zipFile']['name'])) . '"');
    header('Content-Length: ' . filesize($filename));
    header('Expires: 0');
    header('Cache-Control: must-revalidate, post-check=0, pre-check=0');
    header('Pragma: public');
    readfile($filename);
}

