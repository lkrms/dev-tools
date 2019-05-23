<!DOCTYPE html>
<html>

<head>
    <title>Clean HTML</title>
    <meta charset="UTF-8">
    <link rel="stylesheet" href="styles.css<?php  echo '?' . filemtime('styles.css'); ?>">
    <script src="jquery.min.js<?php  echo '?' . filemtime('jquery.min.js'); ?>"></script>
    <script src="tidy.js<?php  echo '?' . filemtime('tidy.js'); ?>"></script>
    <script src="clean-html.js<?php  echo '?' . filemtime('clean-html.js'); ?>"></script>
</head>

<body>
    <div id="source" contenteditable="true"></div>
    <div id="target" contenteditable="true"></div>
    <textarea id="output"></textarea>
    <button id="convert">Convert</button>
    <input type="radio" name="preset" value="swift" id="swiftPreset" checked />
    <label for="swiftPreset">Swift Digital</label>
    <input type="radio" name="preset" value="wp" id="wpPreset" />
    <label for="wpPreset">WordPress</label>
</body>

</html>