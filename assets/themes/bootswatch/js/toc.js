/*!
 * toc - jQuery Table of Contents Plugin
 * v0.3.2
 * http://projects.jga.me/toc/
 *
 * Modified by Guan Gui on 27/11/2014
 * copyright Greg Allen 2014
 * MIT License
 */
/*!
 * smooth-scroller - Javascript lib to handle smooth scrolling
 * v0.1.2
 * https://github.com/firstandthird/smooth-scroller
 * copyright First+Third 2014
 * MIT License
 */
//smooth-scroller.js

(function($) {
  $.fn.smoothScroller = function(options) {
    options = $.extend({}, $.fn.smoothScroller.defaults, options);
    var el = $(this);

    $(options.scrollEl).animate({
      scrollTop: el.offset().top - $(options.scrollEl).offset().top - options.offset
    }, options.speed, options.ease, function() {
      var hash = el.attr('id');

      if (hash.length) {
        if (history.pushState) {
          history.pushState(null, null, '#' + hash);
        } else {
          document.location.hash = hash;
        }
      }

      el.trigger('smoothScrollerComplete');
    });

    return this;
  };

  $.fn.smoothScroller.defaults = {
    speed: 400,
    ease: 'swing',
    scrollEl: 'body',
    offset: 0
  };

  $('body').on('click', '[data-smoothscroller]', function(e) {
    e.preventDefault();
    var href = $(this).attr('href');

    if (href.indexOf('#') === 0) {
      $(href).smoothScroller();
    }
  });
}(jQuery));

(function($) {
  var verboseIdCache = {};
  $.fn.toc = function(options) {
    var self = this;
    var opts = $.extend({}, jQuery.fn.toc.defaults, options);
    $.fn.toc.opts = opts;
    var container = $(opts.container);
    var headings = $(opts.selectors, container);
    var tocEntries = [];
    var headingOffsets = [];

    var caculateHeadingOffset = function(h) {
      return $(h).offset().top - opts.highlightOffset;
    };

    var recaculateHeadingOffsets = function() {
      headings.each(function(i, heading) {
        headingOffsets[i] = caculateHeadingOffset(heading);
      })
    };

    var activeClassName = opts.activeClass;
    var selectedTocEntry;

    var scrollTo = function(e, callback) {
      if (opts.smoothScrolling && typeof opts.smoothScrolling === 'function') {
        e.preventDefault();
        var elScrollTo = $(e.target).attr('href');

        opts.smoothScrolling(elScrollTo, opts, callback);
      }
      if (selectedTocEntry) {
        selectedTocEntry.removeClass(activeClassName);
      }
      selectedTocEntry = $(e.target).parent().addClass(activeClassName);
    };

    if (opts.highlightOnScroll) {
      //highlight on scroll
      var hTimeout;
      var highlightOnScroll = function(e, delay) {
        delay = typeof delay !== 'undefined' ? delay : 50;
        if (hTimeout) {
          clearTimeout(hTimeout);
        }
        hTimeout = setTimeout(function() {
          var top = $(window).scrollTop(),
            index = -1;

          // binary search the index i where headingOffsets[i] <= top < headingOffsets[i+1]
          var left = 0;
          var right = headingOffsets.length - 1;
          while (left <= right) {
            var mid = (left + right) / 2 | 0;
            var midV = headingOffsets[mid];
            if (top >= midV) {
              if (mid + 1 <= right) {
                var midPlus1V = headingOffsets[mid + 1];
                if (top < midPlus1V) {
                  index = mid;
                  break;
                } else {
                  left = mid + 1;
                }
              } else {
                index = mid;
                break;
              }
            } else {
              if (mid - 1 >= 0) {
                var midMinus1V = headingOffsets[mid - 1];
                if (top >= midMinus1V) {
                  index = mid - 1;
                  break;
                } else {
                  right = mid - 1;
                }
              } else {
                index = -1;
                break;
              }
            }
          }

          if (selectedTocEntry) {
            selectedTocEntry.removeClass(activeClassName);
            selectedTocEntry = null;
          }
          if (index != -1) {
            selectedTocEntry = $(tocEntries[index]);
            selectedTocEntry.addClass(activeClassName);
            opts.onHighlight(selectedTocEntry);

            if (opts.autoScrollToc) {
              // automatically scroll TOC so that the highlighted TOC entry remains visible
              var tocTop = self.scrollTop();
              var tocETop = selectedTocEntry.offset().top - $(tocEntries[0]).offset().top + opts.autoScrollTocTopOffset;
              var tocETopRToc = tocETop - tocTop;
              var tocHeight = opts.autoScrollTocHeightFunc ? opts.autoScrollTocHeightFunc() : self.outerHeight();
              var tocEBottomRToc = tocTop + tocHeight - tocETop - selectedTocEntry.outerHeight();
              var threshold = tocHeight * opts.autoScrollTocMarginThreshold;
              var moveDist = 0;
              if (tocETopRToc < threshold) {
                // current TOC entry is above top margin, should move it down
                moveDist = tocETopRToc - threshold;
              } else if (tocEBottomRToc < threshold) {
                // current TOC entry is below bottom margin, should move it up
                moveDist = threshold - tocEBottomRToc;
              }
              if (moveDist != 0) {
                self.animate({
                  scrollTop: tocTop + moveDist
                }, 350, 'swing');
              }
            }
          }
        }, delay);
      };
      // this is to prevent scroll event from firing immediately after bind. This can happen if we just finished scrolling.
      setTimeout(function() {
        $(window).bind('scroll', highlightOnScroll);
      }, 500);

      // prevent auto scroll TOC when user's mouse are over TOC
      self.mouseenter(function() {
        opts.autoScrollToc = false;
      }).mouseleave(function() {
        opts.autoScrollToc = true;
      });

      if (opts.highlightOnStart) {
        highlightOnScroll();
      }

      var rTimeout;
      var highlightOnResize = function(e, delay) {
        delay = typeof delay !== 'undefined' ? delay : 900;
        if (rTimeout) {
          clearTimeout(rTimeout);
        }
        rTimeout = setTimeout(function() {
          recaculateHeadingOffsets();
          highlightOnScroll(null, 0);
        }, delay);
      }
      if (opts.highlightOnWindowResize)
        $(window).resize(highlightOnResize);
      $.fn.toc.rehighlight = highlightOnResize;
    }

    return this.each(function() {
      //build TOC
      var el = $(this);
      var ul = $(opts.listType);

      headings.each(function(i, heading) {
        var $h = $(heading);
        headingOffsets.push(caculateHeadingOffset(heading));

        var anchorName = opts.anchorName(i, heading, opts.prefix);

        //add anchor
        if (heading.id !== anchorName) {
          var anchor = $('<span/>').attr('id', anchorName).insertBefore($h);
        }

        //build TOC item
        var a = $('<a/>')
          .text(opts.headerText(i, heading, $h))
          .attr('href', '#' + anchorName)
          .bind('click', function(e) {
            $(window).unbind('scroll', highlightOnScroll);
            scrollTo(e, function(e) {
              // this is to prevent scroll event from firing immediately after bind. This can happen if we just finished scrolling.
              setTimeout(function() {
                $(window).bind('scroll', highlightOnScroll);
              }, 500);
            });
            el.trigger('selected', $(this).attr('href'));
          });

        var li = $('<li/>')
          .addClass(opts.itemClass(i, heading, $h, opts.prefix))
          .append(a);

        ul.append(li);
      });
      tocEntries = ul.first().children();
      el.html(ul);
    });
  };


  jQuery.fn.toc.defaults = {
    container: 'body',
    listType: '<ul/>',
    selectors: 'h1,h2,h3',
    smoothScrolling: function(target, options, callback) {
      $(target).smoothScroller({
        offset: options.scrollToOffset
      }).on('smoothScrollerComplete', function() {
        callback();
      });
    },
    scrollToOffset: 0,
    prefix: 'toc',
    activeClass: 'toc-active',
    onHighlight: function() {},
    highlightOnScroll: true,
    highlightOffset: 100,
    highlightOnStart: true,
    highlightOnWindowResize: true,
    autoScrollToc: true, // only available if highlightOnScroll is set to true
    autoScrollTocMarginThreshold: 0.2, // in percentage
    autoScrollTocHeightFunc: null,
    autoScrollTocTopOffset: 0, // offset of first TOC entry to the TOC top edge
    anchorName: function(i, heading, prefix) {
      if (heading.id.length) {
        return heading.id;
      }

      var candidateId = $(heading).text().replace(/[^a-z0-9]/ig, ' ').replace(/\s+/g, '-').toLowerCase();
      if (verboseIdCache[candidateId]) {
        var j = 2;

        while (verboseIdCache[candidateId + j]) {
          j++;
        }
        candidateId = candidateId + '-' + j;

      }
      verboseIdCache[candidateId] = true;

      return prefix + '-' + candidateId;
    },
    headerText: function(i, heading, $heading) {
      return $heading.text();
    },
    itemClass: function(i, heading, $heading, prefix) {
      return prefix + '-' + $heading[0].tagName.toLowerCase();
    }
  };

})(jQuery);