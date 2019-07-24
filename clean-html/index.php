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
    <div id="source" class="clean-html-source" contenteditable="true"></div>
    <div id="target" class="clean-html-target" contenteditable="true"></div>
    <textarea id="output" class="clean-html-output"></textarea>
    <button id="convert" class="clean-html-convert">Convert</button>
    <input type="radio" name="preset" id="swiftPreset" class="clean-html-options" checked data-clean-html-options="<?php  echo htmlspecialchars(json_encode( ["replaceBlocks" => "<div></div>", "replaceHeadings" => true, "spacerBetweenBlocks" => true, "targetBlank" => true]), ENT_QUOTES | ENT_HTML5); ?>" />
    <label for="swiftPreset">Swift Digital</label>
    <input type="radio" name="preset" id="wpPreset" class="clean-html-options" data-clean-html-options="{}" />
    <label for="wpPreset">WordPress</label>
</body>

</html>