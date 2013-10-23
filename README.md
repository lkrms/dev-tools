# dev-tools

Feel free to use these in your own development. Bug reports welcome.

### PrettyPhp & PrettyJson

These are the PHP and JSON beautifiers I use.

They're both written in PHP and automatically detect whether they're being hosted or run from a command line.

`pretty.php` is the entry point in either case, e.g.

    $ php pretty-php/pretty.php MyPhpFile.php

Both beautifiers conduct sanity checks prior to re-writing the original file, i.e. they check that the formatted code is parsed with identical results to the original code.

Various settings are available in `pretty_config.php`. When using PrettyPhp, you can vary settings per-file by adding comments like this:

    // PRETTY_NESTED_ARRAYS,0

Everything else should be self-evident. Enjoy!

