$(function () {

    function nodeFilter() {

        // keep: element nodes and text nodes
        // remove: comments, fragments, namespaced elements
        return !(this.nodeType === 1 || this.nodeType === 3) || this.nodeName.match(/:/);

    }

    function noAttributeFilter() {

        return this.attributes.length < 1;

    }

    function textNodeFilter() {

        return this.nodeType === 3;

    }

    function whitespace() {

        return $.parseHTML(" ");

    }

    var wordSeparatorsCharacterClass = [

        '[',

        // whitespace (except \u0020, included below)
        '\f\n\r\t\v\u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff',

        // Unicode: General Punctuation
        '\u2000-\u206F',

        // Unicode: Supplemental Punctuation
        '\u2E00-\u2E7F',

        // Basic Latin (incl. space):  !"#$%&'()*+,-./
        '\u0020-\u002F',

        // Basic Latin: :;<=>?@
        '\u003A-\u0040',

        // Basic Latin: [\]^_`
        '\u005B-\u0060',

        // Basic Latin: {|}~
        '\u007B-\u007E',

        ']'

    ].join('');

    // NOTE: this doesn't match empty strings
    var onlyWordSeparators = new RegExp('^' + wordSeparatorsCharacterClass + '+$');

    var whiteColor = $("<div></div>").css("color", "#fff").css("color");

    $("#convert").click(function () {

        var defaultOptions = {
            "deleteEmptyBlocks": true,
            "maxSubheadingLength": 80,
            "replaceBlocks": "<div></div>",
            "replaceHeadings": true,
            "spacerBetweenBlocks": true,
            "targetBlank": true
        };

        var wpOptions = {
            "deleteEmptyBlocks": true,
            "maxSubheadingLength": 80,
            "replaceBlocks": "<p></p>",
            "replaceHeadings": false,
            "spacerBetweenBlocks": false,
            "targetBlank": false
        };

        var options;

        switch ($("input[name=preset]:checked").val()) {

            case "wp":

                options = wpOptions;
                break;

            default:

                options = defaultOptions;
                break;

        }

        $("#target").empty();

        $("#source").clone().contents().appendTo("#target");

        var p = $("#target");

        // if the entire source was wrapped in one or more single blocks, move everything up
        var replaced;

        do {

            replaced = false;

            p.children("div:only-child, p:only-child").each(function () {

                replaced = true;

                $(this).replaceWith($(this).contents());

            });

        } while (replaced);

        // remove nodes that aren't elements or text (e.g. comments)
        p.contents().filter(nodeFilter).remove();
        p.find("*").contents().filter(nodeFilter).remove();

        // remove embedded CSS
        p.find("style").remove();

        // remove white-coloured text
        p.find("*").filter(function () {

            return $(this).css("color") == whiteColor;

        }).replaceWith(whitespace);

        // convert <span style="font-weight: bold;"> to <span style="font-weight: bold;"><strong>
        // (<span> will be removed later)
        p.find("*").filter(function () {

            if (this.style.fontWeight.match(/^bold/) ||
                (!isNaN(this.style.fontWeight) && parseInt(this.style.fontWeight) >= 550)) {

                return true;

            }

            return false;

        }).each(function () {

            var strong = $("<strong></strong>");

            strong.append($(this).contents());

            $(this).append(strong);

        });

        // convert <span style="font-style: italic;"> to <span style="font-style: italic;"><em>
        // (<span> will be removed later)
        p.find("*").filter(function () {

            switch (this.style.fontStyle) {

                case "italic":
                case "oblique":
                    return true;

                default:
                    return false;

            }

        }).each(function () {

            var em = $("<em></em>");

            em.append($(this).contents());

            $(this).append(em);

        });

        function retainStyle(filter, elementName) {

            var normal = p.find("*").filter(filter);

            normal.each(function () {

                // get the topmost element we descend from
                var el = $(this).parentsUntil(p, elementName).last();

                // (if we descend from one at all)
                if (el.length) {

                    // delete any other elements between us and the topmost one
                    $(this).parentsUntil(el, elementName).each(function () {

                        $(this).replaceWith($(this).contents());

                    });

                    // we definitely don't want to apply formatting to any of our parents
                    var exclude = $(this).parentsUntil(el);

                    // now, work down from the top and apply formatting where it might remain relevant
                    var children = el.children();
                    var parents = el;

                    while (children.length) {

                        // if we have any children that aren't explicitly "normal", apply formatting to them
                        children.not(elementName).not(normal).not(exclude).each(function () {

                            var cel = $("<" + elementName + "></" + elementName + ">");

                            $(this).after(cel);

                            cel.append(this);

                        });

                        parents = parents.children().not(elementName).not(normal);
                        children = parents.children();

                    }

                    // finally, delete the topmost element
                    el.replaceWith(el.contents());

                }

            });

        }

        var styleNormalFilter = function () {

            return this.style.fontStyle == "normal";

        }

        var weightNormalFilter = function () {

            if (this.style.fontWeight &&
                !(this.style.fontWeight.match(/^bold/) ||
                    (!isNaN(this.style.fontWeight) && parseInt(this.style.fontWeight) >= 550))) {

                return true;

            }

            return false;

        }

        // check for "normal" text nested in em's, strong's, etc.
        retainStyle(styleNormalFilter, "em");
        retainStyle(styleNormalFilter, "i");
        retainStyle(weightNormalFilter, "strong");
        retainStyle(weightNormalFilter, "b");

        // convert email addresses to links (if they're not already in links)
        p.find("*").contents().filter(textNodeFilter).filter(function () {

            return !$(this).parentsUntil(p, "a").length;

        }).each(function () {

            var text = $(this).text();
            var originalText = text;

            var re = /\b([a-z0-9._-]+@[a-z0-9._-]+\.[a-z0-9._-]+)\b/i;
            text = text.replace(re, '<a href="mailto:$1">$1</a>');

            if (text != originalText) {

                $(this).replaceWith(text);

            }

        });

        // remove blocks with nothing but whitespace inside
        p.find("div:empty, p:empty").remove();

        if (options.deleteEmptyBlocks) {

            p.find("div, p").filter(function () {

                return $(this).text().trim() == "";

            }).replaceWith(whitespace);

        }

        // clear unwanted attributes
        p.find("[class]").removeAttr("class");
        p.find("[dir]").removeAttr("dir");
        p.find("[lang]").removeAttr("lang");
        p.find("[style]").removeAttr("style");
        p.find("[tabindex]").removeAttr("tabindex");
        p.find("[title]").removeAttr("title");
        p.find("a[rel]").removeAttr("rel");

        // matched elements are removed from the tree, their children moved up to take their place
        p.find("font, a, li > p, a u, u u").not("a[href], a[name]:empty, a[id]:empty").each(function () {

            $(this).replaceWith($(this).contents());

        });

        // copy deprecated names to id attribute
        p.find("a[name]").not("a[id]").each(function () {

            this.id = this.name;

        });

        p.find("span").filter(noAttributeFilter).each(function () {

            $(this).replaceWith($(this).contents());

        });

        // remove superfluous underlines around links
        p.find("u > a:only-child").parent().each(function () {

            $(this).replaceWith($(this).contents());

        });

        // remove unnecessary non-breaking spaces
        p.html(function (i, html) {

            return html.replace(/(&nbsp;|&#160;)/g, " ");

        });

        // find inline elements that aren't so-called "void elements" and clean them up if they're empty or only contain whitespace
        p.find(":not(area,base,br,col,embed,hr,img,input,keygen,link,meta,param,source,track,wbr)").filter(function () {

            return $(this).css("display") == "inline";

        }).each(function () {

            if (this.innerHTML == "") {

                $(this).remove();

            } else if (this.innerHTML.trim() == "") {

                $(this).replaceWith(whitespace);

            } else if (this.innerText.match(onlyWordSeparators)) {

                // replace inline elements that only contain punctuation and/or whitespace with their contents
                $(this).replaceWith($(this).contents());

            } else {

                // protect leading whitespace from tidy_html5 (trailing seems to be safe)
                if (this.innerHTML.match(/^\s/)) {

                    $(this).before(whitespace);

                }

            }

        });

        // replace headings with <div><strong>
        if (options.replaceHeadings) {

            p.find("h1, h2, h3, h4, h5, h6").each(function () {

                var div = $("<div><strong></strong></div>");

                if (this.id) {

                    div[0].id = this.id;

                }

                div.children().first().append($(this).contents());

                $(this).replaceWith(div);

            });

        }

        var bulletPoints = /^(\u00B7[ ]*)/;

        p.find("*").contents().filter(textNodeFilter).filter(function () {

            // has to be the first child of its parent (i.e. the bullet must be at the start of the block)
            return !this.previousElementSibling && this.nodeValue.match(bulletPoints);

        }).each(function () {

            this.nodeValue = this.nodeValue.replace(bulletPoints, '');

            var parent = $(this).parent();
            var ul = $("<ul><li></li></ul>");

            if (parent[0].id) {

                ul[0].id = parent[0].id;

            }

            ul.children().first().append(parent.contents());

            parent.replaceWith(ul);

        });

        // merge sibling lists
        p.find("ul, ol").each(function () {

            if (($(this).is("ul") && $(this).prev().is("ul")) || ($(this).is("ol") && $(this).prev().is("ol"))) {

                $(this).prev().append($(this).children());
                $(this).remove();

            }

        });

        // specify target=_blank for all links (except mailto's)
        if (options.targetBlank) {

            p.find("a").each(function () {

                if (!this.href.match(/^mailto:/)) {

                    $(this).attr("target", "_blank");

                } else {

                    $(this).removeAttr("target");

                }

            });

        }

        // matched elements are replaced with divs
        if (options.replaceBlocks) {

            p.find("div, p").each(function () {

                var newBlock = $(options.replaceBlocks);

                if (this.id) {

                    newBlock[0].id = this.id;

                }

                $(this).replaceWith(newBlock.append($(this).contents()));

            });

        }

        // e.g. <b><b><b>Text</b></b></b> -> <b>Text</b>
        do {

            replaced = false;

            p.children().find(":only-child").filter("div, p, strong, b, em, i").filter(function () {

                return this.parentElement.nodeName == this.nodeName;

            }).parent().each(function () {

                replaced = true;

                $(this).replaceWith($(this).contents());

            });

        } while (replaced);

        var wastedFormatting = new RegExp("</(b|strong|i|em|u)>(" + wordSeparatorsCharacterClass + "*)<\\1>", "gi");

        p.find("*").filter(function () {

            // check that we're a 'block' with no 'block' children
            return $(this).css("display") == "block" && !$(this).children().filter(function () {

                return $(this).css("display") == "block";

            }).length;

        }).html(function (i, html) {

            // e.g. "</b> <b>" -> " "
            return html.replace(wastedFormatting, "$2");

        });

        // tidy up any stray line breaks
        p.find("*").filter(function () {

            return $(this).css("display") != "inline";

        }).each(function () {

            var $child;

            while (this.firstChild && this.firstChild.nodeType === 1 && ($child = $(this.firstChild)).is("br")) {

                $child.remove();

            }

            while (this.lastChild && this.lastChild.nodeType === 1 && ($child = $(this.lastChild)).is("br")) {

                $child.remove();

            }

        }).find("*").contents().filter(textNodeFilter).each(function () {

            if (!$(this.parentElement).parentsUntil(p).add(this.parentElement).filter(function () {
                return $(this).data("alreadySplit") === true;
            }).length) {

                var nn = this.parentElement.nodeName.toLowerCase();

                this.parentElement.outerHTML = this.parentElement.outerHTML.replace(/(<br\s*\/?>\s*){2,}/gi, "</" + nn + "><" + nn + ">");

                $(this.parentElement).data("alreadySplit", true);

            }

        });

        // matched elements (at the top level only) get a spacer inserted after them
        if (options.spacerBetweenBlocks) {

            p.children("div, p").each(function () {

                if (!$(this).next().is("ul, ol")
                    && !($(this).children().is("b:only-child, strong:only-child, i:only-child, em:only-child") && $(this).children().text().trim() == $(this).text().trim() && $(this).text().trim().length <= options.maxSubheadingLength)
                ) {

                    $(this).after($("<div>&nbsp;</div>"))

                }

            });

        }

        // built from https://github.com/lkrms/tidy-html5
        // using https://emscripten.org
        // see http://api.html-tidy.org/tidy/quickref_5.6.0.html
        var tidyOptions = {
            "break-before-br": true,
            "drop-empty-elements": false,
            "drop-empty-paras": false,
            "indent-spaces": 2,
            "indent": "auto",
            "logical-emphasis": true,           // replace <i> with <em> and <b> with <strong>
            "numeric-entities": false,
            "preserve-entities": true,
            "quote-ampersand": true,
            "quote-marks": false,
            "show-body-only": true,
            "tidy-mark": false,
            "wrap": 0
        };

        var output = tidy_html5(p.html(), tidyOptions);

        $("#output").val(output);

    });

});
