;(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
(function() {
  var module;

  require("../services/session.coffee");

  require("../directives/borderLayout.coffee");

  require("../directives/codeEditor.coffee");

  require("../directives/previewer.coffee");

  module = angular.module("plunker.app.editor", ["fa.borderLayout", "plunker.service.session", "plunker.directive.codeEditor", "plunker.directive.previewer"]);

  module.controller("Editor", [
    "$scope", "session", function($scope, session) {
      var client;
      client = session.createClient("MainCtrl");
      $scope.session = client;
      client.reset({
        files: [
          {
            filename: "index.html",
            content: "<!doctype html>\n<html ng-app=\"plunker\" >\n<head>\n  <meta charset=\"utf-8\">\n  <title>AngularJS Plunker</title>\n  <script>document.write('<base href=\"' + document.location + '\" />');</script>\n  <link rel=\"stylesheet\" href=\"style.css\">\n  <script data-require=\"angular.js@1.1.x\" src=\"http://code.angularjs.org/1.1.4/angular.js\"></script>\n  <script src=\"app.js\"></script>\n</head>\n<body ng-controller=\"MainCtrl\">\n  <p>Hello {{name}}!</p>\n</body>\n</html> "
          }, {
            filename: "app.js",
            content: "var app = angular.module('plunker', []);\n \napp.controller('MainCtrl', function($scope) {\n  $scope.name = 'World';\n});"
          }, {
            filename: "style.css",
            content: "p {\n  color: red;\n}"
          }
        ]
      });
      $scope.addFile = function() {
        var filename;
        if (filename = prompt("Filename?")) {
          client.fileCreate(filename);
          return client.cursorSetFile(filename);
        }
      };
      $scope.renameFile = function(old_filename) {
        var filename;
        if (client.hasFile(old_filename) && (filename = prompt("Filename?", old_filename))) {
          return client.fileRename(old_filename, filename);
        }
      };
      $scope.removeFile = function(filename) {
        if (client.hasFile(filename) && confirm("Are you sure you would like to delete " + filename + "?")) {
          return client.fileRemove(filename);
        }
      };
      return $scope.moveTo = function(filename) {
        return client.cursorSetFile(filename);
      };
    }
  ]);

}).call(this);


},{"../directives/borderLayout.coffee":2,"../directives/codeEditor.coffee":3,"../directives/previewer.coffee":4,"../services/session.coffee":6}],2:[function(require,module,exports){
(function() {
  var Region, module, throttle,
    __slice = [].slice;

  module = angular.module("fa.borderLayout", []);

  throttle = function(delay, fn) {
    var throttled;
    throttled = false;
    return function() {
      if (throttled) {
        return;
      }
      throttled = true;
      setTimeout(function() {
        return throttled = false;
      }, delay);
      return fn.call.apply(fn, [this].concat(__slice.call(arguments)));
    };
  };

  Region = (function() {
    function Region(width, height) {
      this.width = width != null ? width : 0;
      this.height = height != null ? height : 0;
      this.top = 0;
      this.right = 0;
      this.bottom = 0;
      this.left = 0;
    }

    Region.prototype.calculateSize = function(orientation, target) {
      var matches, terms, total;
      if (target == null) {
        target = 0;
      }
      total = this.getSize(orientation);
      if (angular.isNumber(target)) {
        if (target >= 1) {
          return Math.round(target);
        }
        if (target >= 0) {
          return Math.round(target * total);
        }
        return 0;
      }
      target = target.replace(/\s+/mg, "");
      if ((terms = target.split("-", 2)).length === 2) {
        return this.calculateSize(orientation, terms[0]) - this.calculateSize(orientation, terms[1]);
      }
      if ((terms = target.split("+", 2)).length === 2) {
        return this.calculateSize(orientation, terms[0]) + this.calculateSize(orientation, terms[1]);
      }
      if (matches = target.match(/^(\d+)px$/)) {
        return parseInt(matches[1], 10);
      }
      if (matches = target.match(/^(\d+(?:\.\d+)?)%$/)) {
        return Math.round(total * parseFloat(matches[1]) / 100);
      }
      throw new Error("Unsupported size: " + target);
    };

    Region.prototype.consume = function(anchor, size) {
      var style;
      if (size == null) {
        size = 0;
      }
      switch (anchor) {
        case "north":
          style = {
            top: "" + this.top + "px",
            right: "" + this.right + "px",
            left: "" + this.left + "px",
            height: "" + size + "px"
          };
          this.top += size;
          break;
        case "east":
          style = {
            top: "" + this.top + "px",
            right: "" + this.right + "px",
            bottom: "" + this.bottom + "px",
            width: "" + size + "px"
          };
          this.right += size;
          break;
        case "south":
          style = {
            right: "" + this.right + "px",
            bottom: "" + this.bottom + "px",
            left: "" + this.left + "px",
            height: "" + size + "px"
          };
          this.bottom += size;
          break;
        case "west":
          style = {
            top: "" + this.top + "px",
            bottom: "" + this.bottom + "px",
            left: "" + this.left + "px",
            width: "" + size + "px"
          };
          this.left += size;
      }
      return style;
    };

    Region.prototype.getInnerRegion = function() {
      return new Region(this.width - this.right - this.left, this.height - this.top - this.bottom);
    };

    Region.prototype.getSize = function(orientation) {
      switch (orientation) {
        case "vertical":
          return this.height;
        case "horizontal":
          return this.width;
      }
    };

    Region.prototype.getAvailableSize = function(orientation) {
      switch (orientation) {
        case "vertical":
          return this.height - this.top - this.bottom;
        case "horizontal":
          return this.width - this.right - this.left;
      }
    };

    return Region;

  })();

  module.directive("pane", [
    function() {
      return {
        restrict: "E",
        replace: true,
        require: ["pane", "^borderLayout"],
        transclude: true,
        scope: true,
        template: "<div class=\"border-layout-pane\" ng-class=\"{closed: !open}\" ng-style=\"stylePane\">\n  <div class=\"border-layout-pane-overlay\" ng-style=\"styleContent\"></div>\n  <div class=\"border-layout-pane-handle\" layout-handle ng-style=\"styleHandle\"></div>\n  <div class=\"border-layout-pane-scroller\" ng-style=\"styleContent\" ng-transclude></div>\n</div>",
        controller: [
          "$scope", "$element", "$attrs", function($scope, $element, $attrs) {
            var pane;
            pane = this;
            $attrs.$observe("anchor", function(anchor) {
              pane.anchor = anchor;
              return pane.orientation = pane.getOrientation(anchor);
            });
            $attrs.$observe("open", function(open, wasOpen) {
              if (open == null) {
                open = true;
              }
              return $scope.open = !!open;
            });
            this.children = [];
            this.openSize = 0;
            this.attachChild = function(child) {
              return this.children.push(child);
            };
            this.getAnchor = function() {
              return $attrs.anchor;
            };
            this.getOrientation = function(anchor) {
              if (anchor == null) {
                anchor = $attrs.anchor;
              }
              switch (anchor) {
                case "north":
                case "south":
                  return "vertical";
                case "east":
                case "west":
                  return "horizontal";
              }
            };
            this.getContentStyle = function(anchor, handleSize) {
              var style;
              style = {
                top: 0,
                right: 0,
                bottom: 0,
                left: 0
              };
              switch (anchor) {
                case "north":
                  style.bottom = "" + handleSize + "px";
                  break;
                case "east":
                  style.left = "" + handleSize + "px";
                  break;
                case "south":
                  style.top = "" + handleSize + "px";
                  break;
                case "west":
                  style.right = "" + handleSize + "px";
              }
              return style;
            };
            this.getHandleStyle = function(anchor, region, handleSize) {
              switch (anchor) {
                case "north":
                  return {
                    height: "" + (region.calculateSize('vertical', handleSize)) + "px",
                    right: 0,
                    left: 0,
                    bottom: 0
                  };
                case "south":
                  return {
                    height: "" + (region.calculateSize('vertical', handleSize)) + "px",
                    right: 0,
                    left: 0,
                    top: 0
                  };
                case "east":
                  return {
                    width: "" + (region.calculateSize('horizontal', handleSize)) + "px",
                    top: 0,
                    bottom: 0,
                    left: 0
                  };
                case "west":
                  return {
                    width: "" + (region.calculateSize('horizontal', handleSize)) + "px",
                    top: 0,
                    bottom: 0,
                    right: 0
                  };
              }
            };
            this.onHandleDown = function() {
              $element.addClass("active");
              return this.layout.onHandleDown();
            };
            this.onHandleUp = function() {
              $element.removeClass("active");
              return this.layout.onHandleUp();
            };
            this.toggle = function(closed) {
              if (closed == null) {
                closed = !$scope.closed;
              }
              $scope.closed = !!closed;
              if (closed) {
                this.openSize = this.size;
              } else {
                this.size = this.openSize;
              }
              return this.layout.reflow();
            };
            this.reflow = function(region, target) {
              var anchor, child, handleSize, inner, max, min, orientation, size, _i, _len, _ref;
              if (target == null) {
                target = $attrs.size;
              }
              anchor = $attrs.anchor;
              if (anchor === "center") {
                $scope.stylePane = {
                  top: "" + region.top + "px",
                  right: "" + region.right + "px",
                  bottom: "" + region.bottom + "px",
                  left: "" + region.left + "px"
                };
              } else {
                orientation = this.getOrientation(anchor);
                handleSize = region.calculateSize(orientation, $attrs.handle || 0);
                if ($scope.closed) {
                  size = handleSize;
                } else {
                  size = region.calculateSize(orientation, target);
                  max = $attrs.max || Number.MAX_VALUE;
                  min = $attrs.min || 0;
                  size = Math.min(size, region.calculateSize(orientation, max));
                  size = Math.max(size, region.calculateSize(orientation, min));
                  size = Math.min(size, region.getAvailableSize(orientation));
                  size = Math.max(size, handleSize + 2);
                }
                this.size = size;
                $scope.stylePane = region.consume(anchor, size);
                $scope.styleContent = this.getContentStyle(anchor, handleSize);
                $scope.styleHandle = this.getHandleStyle(anchor, region, handleSize);
              }
              if (this.children.length) {
                inner = region.getInnerRegion();
                _ref = this.children;
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  child = _ref[_i];
                  inner = child.reflow(inner);
                }
              }
              return region;
            };
            return this.resize = function(target) {
              $attrs.$set("size", target || 0);
              return this.layout.reflow();
            };
          }
        ],
        link: function($scope, $el, $attrs, _arg) {
          var pane, parent;
          pane = _arg[0], parent = _arg[1];
          pane.layout = parent;
          parent.attachChild(pane);
          return $scope.$watch("constrained", function(constrained) {
            if (constrained) {
              return $el.addClass("border-layout-constrained");
            } else {
              return $el.removeClass("border-layout-constrained");
            }
          });
        }
      };
    }
  ]);

  module.directive("layoutHandle", [
    "$window", function($window) {
      return {
        restrict: "A",
        require: ["?^pane", "^?borderLayout"],
        link: function($scope, $element, $attrs, _arg) {
          var clickRadius, clickTime, el, layout, pane;
          pane = _arg[0], layout = _arg[1];
          if (!pane) {
            return;
          }
          el = $element[0];
          clickRadius = 5;
          clickTime = 300;
          $scope.$watch((function() {
            return pane.getOrientation();
          }), function(orientation) {
            switch (orientation) {
              case "vertical":
                return $element.addClass("vertical");
              case "horizontal":
                return $element.addClass("horizontal");
            }
          });
          return el.addEventListener("mousedown", function(e) {
            var anchor, coord, handleClick, handleMouseMove, handleMouseMoveThrottled, handleMouseUp, scale, startCoord, startPos, startSize, startTime;
            if (e.button !== 0) {
              return;
            }
            anchor = pane.getAnchor();
            if (anchor === "north" || anchor === "south") {
              coord = "screenY";
            } else if (anchor === "west" || anchor === "east") {
              coord = "screenX";
            }
            if (anchor === "north" || anchor === "west") {
              scale = 1;
            } else if (anchor === "south" || anchor === "east") {
              scale = -1;
            }
            startPos = {
              x: e.screenX,
              y: e.screenY
            };
            startCoord = e[coord];
            startSize = pane.size;
            startTime = Date.now();
            pane.onHandleDown();
            el.unselectable = "on";
            el.onselectstart = function() {
              return false;
            };
            el.style.userSelect = el.style.MozUserSelect = "none";
            e.preventDefault();
            e.defaultPrevented = true;
            e = null;
            handleClick = function(e) {
              return $scope.$apply(function() {
                return pane.toggle();
              });
            };
            handleMouseMove = function(e) {
              $element.addClass("border-layout-pane-moving");
              $scope.$apply(function() {
                var targetSize;
                return pane.resize(targetSize = startSize + scale * (e[coord] - startCoord));
              });
              e.preventDefault();
              e.defaultPrevented = true;
              return e = null;
            };
            handleMouseUp = function(e) {
              var cleanup, displacementSq, timeElapsed;
              displacementSq = Math.pow(e.screenX - startPos.x, 2) + Math.pow(e.screenY - startPos.y, 2);
              timeElapsed = Date.now() - startTime;
              $window.removeEventListener("mousemove", handleMouseMoveThrottled, true);
              $window.removeEventListener("mouseup", handleMouseUp, true);
              cleanup = function() {
                e.preventDefault();
                e.defaultPrevented = true;
                e = null;
                return pane.onHandleUp();
              };
              if (displacementSq <= Math.pow(clickRadius, 2) && timeElapsed <= clickTime) {
                handleClick(e);
                cleanup();
                return;
              }
              handleMouseMove(e);
              return cleanup();
            };
            handleMouseMoveThrottled = throttle(10, handleMouseMove);
            $window.addEventListener("mousemove", handleMouseMoveThrottled, true);
            return $window.addEventListener("mouseup", handleMouseUp, true);
          });
        }
      };
    }
  ]);

  module.directive("borderLayout", [
    "$window", "$timeout", function($window, $timeout) {
      return {
        restrict: "E",
        replace: true,
        require: ["borderLayout", "^?pane"],
        transclude: true,
        template: "<div class=\"border-layout\" ng-transclude>\n</div>",
        controller: [
          "$scope", "$element", "$attrs", function($scope, $element, $attrs) {
            var layout;
            layout = this;
            this.children = [];
            this.attachChild = function(child) {
              return this.children.push(child);
            };
            this.onHandleDown = function() {
              return $element.addClass("active");
            };
            this.onHandleUp = function() {
              $element.removeClass("active");
              return $scope.$broadcast("border-layout-reflow");
            };
            return this.reflow = function(region) {
              var child, height, width, _i, _len, _ref, _results;
              width = $element[0].offsetWidth;
              height = $element[0].offsetHeight;
              region || (region = new Region(width, height));
              _ref = this.children;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                child = _ref[_i];
                _results.push(region = child.reflow(region));
              }
              return _results;
            };
          }
        ],
        link: function($scope, $el, $attrs, _arg) {
          var layout, parent;
          layout = _arg[0], parent = _arg[1];
          if (parent) {
            parent.attachChild(layout);
          }
          $scope.$on("reflow", function() {
            if (!parent) {
              return layout.reflow();
            }
          });
          $window.addEventListener("resize", function(e) {
            e.stopPropagation();
            return $scope.$apply(function() {
              return $scope.$broadcast("border-layout-reflow");
            });
          });
          return $timeout(function() {
            if (!parent) {
              return layout.reflow();
            }
          });
        }
      };
    }
  ]);

}).call(this);


},{}],3:[function(require,module,exports){
(function() {
  var module;

  require("../services/session.coffee");

  require("../services/types.coffee");

  require("../services/settings.coffee");

  require("../services/annotations.coffee");

  module = angular.module("plunker.directive.codeEditor", ["plunker.service.session", "plunker.service.types", "plunker.service.settings", "plunker.service.annotations"]);

  module.directive("codeEditor", [
    "$rootScope", "$timeout", "session", "types", "settings", "annotations", function($rootScope, $timeout, session, types, settings, annotations) {
      var AceEditor, EditSession, Range, Renderer, UndoManager, config;
      AceEditor = ace.require("ace/editor").Editor;
      Renderer = ace.require("ace/virtual_renderer").VirtualRenderer;
      EditSession = ace.require("ace/edit_session").EditSession;
      UndoManager = ace.require("ace/undomanager").UndoManager;
      Range = ace.require("ace/range").Range;
      config = ace.require("ace/config");
      return {
        restrict: "E",
        replace: true,
        scope: {
          active: "="
        },
        template: "<div class=\"code-editor\">\n</div>",
        link: function($scope, $el, attrs) {
          var activateBuffer, addAceSession, buffers, changeSessionMode, client, editor, guessMode, moveCursor, removeAceSession, reset, snippetManager;
          editor = new AceEditor(new Renderer($el[0], "ace/theme/" + settings.editor.theme));
          client = session.createClient("code-editor");
          snippetManager = null;
          buffers = [];
          ace.config.loadModule("ace/ext/language_tools", function() {
            editor.setOptions({
              enableBasicAutocompletion: true,
              enableSnippets: true
            });
            return snippetManager = ace.require("ace/snippets").snippetManager;
          });
          $scope.$watch((function() {
            return settings.editor.theme;
          }), function(theme) {
            if (theme) {
              return editor.setTheme("ace/theme/" + theme);
            }
          });
          guessMode = function(filename) {
            return "ace/mode/" + types.getByFilename(filename).name;
          };
          activateBuffer = function(index) {
            editor.setSession(buffers[index]);
            return editor.focus();
          };
          moveCursor = function(offset) {
            var doc;
            doc = editor.session.doc;
            return editor.moveCursorToPosition(doc.indexToPosition(offset));
          };
          addAceSession = function(index, file) {
            var aceSession, doc, handleChangeAnnotationEvent, handleChangeEvent;
            aceSession = new EditSession(file.content || "");
            aceSession.setUndoManager(new UndoManager());
            aceSession.setUseWorker(true);
            aceSession.setTabSize(settings.editor.tab_size);
            aceSession.setUseWrapMode(!!settings.editor.wrap.enabled);
            aceSession.setWrapLimitRange(settings.editor.wrap.range.min, settings.editor.wrap.range.max);
            aceSession.setMode(guessMode(file.filename));
            doc = aceSession.getDocument();
            handleChangeEvent = function(e) {
              if (!$rootScope.$$phase) {
                return $scope.$apply(function() {
                  switch (e.data.action) {
                    case "insertText":
                      return client.textInsert(file.filename, doc.positionToIndex(e.data.range.start), e.data.text);
                    case "insertLines":
                      return client.textInsert(file.filename, doc.positionToIndex(e.data.range.start), e.data.lines.join(e.data.nl) + e.data.nl);
                    case "removeText":
                      return client.textRemove(file.filename, doc.positionToIndex(e.data.range.start), e.data.text);
                    case "removeLines":
                      return client.textRemove(file.filename, doc.positionToIndex(e.data.range.start), e.data.lines.join(e.data.nl) + e.data.nl);
                  }
                });
              }
            };
            handleChangeAnnotationEvent = function(e) {
              if (!$rootScope.$$phase) {
                return $scope.$apply(function() {
                  var idx;
                  if ((idx = client.getFileIndex(file.filename)) < 0) {
                    throw new Error("Buffers and session are out of sync for: " + file.filename);
                  }
                  return annotations.update(file.filename, aceSession.getAnnotations());
                });
              }
            };
            buffers[index] = aceSession;
            annotations.update(file.filename, aceSession.getAnnotations());
            aceSession.on("change", handleChangeEvent);
            aceSession.on("changeAnnotation", handleChangeAnnotationEvent);
            return aceSession.destroy = function() {
              aceSession.off("change", handleChangeEvent);
              return aceSession.off("changeAnnotation", handleChangeAnnotationEvent);
            };
          };
          removeAceSession = function(index) {
            buffers[index].destroy();
            buffers.splice(index, 1);
            return annotations.remove(file.filename);
          };
          reset = function(snapshot) {
            var aceSession, file, idx, _i, _j, _len, _len1, _ref, _results;
            for (idx = _i = 0, _len = buffers.length; _i < _len; idx = ++_i) {
              aceSession = buffers[idx];
              removeAceSession(idx);
            }
            _ref = snapshot.files;
            _results = [];
            for (idx = _j = 0, _len1 = _ref.length; _j < _len1; idx = ++_j) {
              file = _ref[idx];
              _results.push(addAceSession(idx, file));
            }
            return _results;
          };
          changeSessionMode = function(index, filename) {
            var buffer;
            if (buffer = buffers[index]) {
              return buffer.setMode(guessMode(filename));
            }
          };
          client.on("reset", function(e, snapshot) {
            return reset(e.snapshot);
          });
          client.on("cursorSetFile", function(e, snapshot) {
            return activateBuffer(e.index);
          });
          client.on("cursorSetOffset", function(e, snapshot) {
            return moveCursor(e.offset);
          });
          client.on("fileCreate", function(e, snapshot) {
            return addAceSession(e.index, snapshot.files[e.index]);
          });
          client.on("fileRemove", function(e, snapshot) {
            removeAceSession(e.index);
            return annotations.remove(e.filename);
          });
          client.on("fileRename", function(e, snapshot) {
            changeSessionMode(e.index, e.filename);
            console.log("onFileRename", e);
            return annotations.rename(e.filename, e.old_filename);
          });
          client.on("textInsert", function(e, snapshot) {
            var aceSession;
            if (!(aceSession = buffers[e.index])) {
              throw new Error("Received textInsert event for a file not being tracked");
            }
            return aceSession.doc.insert(aceSession.doc.indexToPosition(e.offset), text);
          });
          client.on("textRemove", function(e, snapshot) {
            var aceSession;
            if (!(aceSession = buffers[e.index])) {
              throw new Error("Received textInsert event for a file not being tracked");
            }
            return aceSession.doc.remove(Range.fromPoints(aceSession.doc.indexToPosition(e.offset), aceSession.doc.indexToPosition(e.offset + e.text.length)));
          });
          reset(client.getSnapshot());
          activateBuffer(client.getCursorFileIndex());
          moveCursor(client.getCursorTextOffset());
          return $scope.$on("border-layout-reflow", function() {
            return editor.resize();
          });
        }
      };
    }
  ]);

}).call(this);


},{"../services/annotations.coffee":5,"../services/session.coffee":6,"../services/settings.coffee":7,"../services/types.coffee":8}],4:[function(require,module,exports){
(function() {
  var debounce, genid, module;

  genid = require("genid");

  debounce = require("lodash.debounce");

  require("../../vendor/operative.js");

  require("../services/session.coffee");

  require("../services/types.coffee");

  require("../services/url.coffee");

  require("../services/settings.coffee");

  require("../services/annotations.coffee");

  module = angular.module("plunker.directive.previewer", ["plunker.service.session", "plunker.service.url", "plunker.service.settings", "plunker.service.annotations"]);

  module.directive("previewer", [
    "$timeout", "session", "url", "settings", "annotations", function($timeout, session, url, settings, annotations) {
      return {
        restrict: "E",
        replace: true,
        scope: {
          session: "="
        },
        template: "<div>\n  <div class=\"plunker-preview-container\" ng-class=\"{message: message}\">\n    <iframe name=\"plunkerPreviewTarget\" src=\"about:blank\" width=\"100%\" height=\"400px\" frameborder=\"0\"></iframe>\n  </div>\n  <div class=\"plunker-preview-message alert alert-danger\" ng-show=\"message\">\n    <button type=\"button\" class=\"close\" ng-click=\"message=''\" aria-hidden=\"true\">&times;</button>\n    <span ng-bind=\"message\"></span>\n  </div>\n</div>",
        link: function($scope, $el, attrs) {
          var client, refresh;
          $scope.previewUrl || ($scope.previewUrl = "" + url.run + "/" + (genid()) + "/");
          client = session.createClient("previewer");
          refresh = function(snapshot) {
            return $scope.$apply(function() {
              var field, file, filename, form, _i, _len, _ref;
              console.log("Refresh", snapshot, annotations.hasError(), annotations.annotations);
              if ($scope.mode === "disabled") {
                return;
              }
              if (filename = annotations.hasError()) {
                $scope.message = "Preview has not been updated due to syntax errors in " + filename;
                return;
              } else {
                $scope.message = "";
              }
              form = document.createElement("form");
              form.style.display = "none";
              form.setAttribute("method", "post");
              form.setAttribute("action", $scope.previewUrl);
              form.setAttribute("target", "plunkerPreviewTarget");
              _ref = snapshot.files;
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                file = _ref[_i];
                field = document.createElement("input");
                field.setAttribute("type", "hidden");
                field.setAttribute("name", "files[" + file.filename + "][content]");
                field.setAttribute("value", file.content);
                form.appendChild(field);
              }
              document.body.appendChild(form);
              form.submit();
              return document.body.removeChild(form);
            });
          };
          $scope.$watch((function() {
            return settings.previewer.delay;
          }), function(delay) {
            return refresh = debounce(refresh, delay);
          });
          client.on("reset", function(e, snapshot) {
            return refresh(snapshot);
          });
          client.on("fileCreate", function(e, snapshot) {
            return refresh(snapshot);
          });
          client.on("fileRename", function(e, snapshot) {
            return refresh(snapshot);
          });
          client.on("fileRemove", function(e, snapshot) {
            return refresh(snapshot);
          });
          client.on("textInsert", function(e, snapshot) {
            return refresh(snapshot);
          });
          client.on("textRemove", function(e, snapshot) {
            return refresh(snapshot);
          });
          return $timeout(function() {
            return refresh(client.getSnapshot());
          });
        }
      };
    }
  ]);

}).call(this);


},{"../../vendor/operative.js":10,"../services/annotations.coffee":5,"../services/session.coffee":6,"../services/settings.coffee":7,"../services/types.coffee":8,"../services/url.coffee":9,"genid":12,"lodash.debounce":13}],5:[function(require,module,exports){
(function() {
  var module;

  module = angular.module("plunker.service.annotations", []);

  module.factory("annotations", function() {
    return {
      annotations: {},
      update: function(filename, annotations) {
        var _base;
        if (annotations == null) {
          annotations = [];
        }
        return angular.copy(annotations, ((_base = this.annotations)[filename] || (_base[filename] = [])));
      },
      rename: function(old_filename, new_filename) {
        this.annotations[new_filename] = this.annotations[old_filename] || [];
        return delete this.annotations[old_filename];
      },
      remove: function(filename) {
        return delete this.annotations[filename];
      },
      hasError: function() {
        var annotation, annotations, filename, _i, _len, _ref;
        _ref = this.annotations;
        for (filename in _ref) {
          annotations = _ref[filename];
          for (_i = 0, _len = annotations.length; _i < _len; _i++) {
            annotation = annotations[_i];
            if (annotation.type === "error") {
              return filename;
            }
          }
        }
        return false;
      }
    };
  });

}).call(this);


},{}],6:[function(require,module,exports){
(function() {
  var Session, module;

  require("../../vendor/ottypes/webclient/json0.uncompressed.js");

  module = angular.module("plunker.service.session", []);

  module.service("session", Session = (function() {
    var SessionClient;

    SessionClient = (function() {
      function SessionClient(name, session) {
        this.name = name;
        this.session = session;
        this.listeners = {};
      }

      SessionClient.prototype.on = function(eventName, listener) {
        var _base;
        return ((_base = this.listeners)[eventName] || (_base[eventName] = [])).push(listener);
      };

      SessionClient.prototype.off = function(eventName, listener) {
        var idx;
        if (!(0 > (idx = this.listeners.indexOf(listener)))) {
          return this.listeners.splice(idx, 1);
        }
      };

      SessionClient.prototype._applyOp = function(op) {
        return this._applyOps([op]);
      };

      SessionClient.prototype._applyOps = function(ops) {
        return this.session.applyOps(this.name, ops);
      };

      SessionClient.prototype._handleOp = function(sourceClientName, op, snapshot) {
        var filename;
        if (op.p.length === 0) {
          return this._emit("reset", {
            snapshot: op.oi,
            old_snapshot: op.od
          });
        } else {
          switch (op.p[0]) {
            case "cursor":
              if (op.p[1] === "fileIndex") {
                return this._emit("cursorSetFile", {
                  filename: snapshot.files[op.oi].filename,
                  prev_filename: snapshot.files[op.od].filename,
                  index: op.oi,
                  prev_index: op.od
                });
              } else if (op.p[1] === "textOffset") {
                return this._emit("cursorSetOffset", {
                  offset: op.oi,
                  prev_offset: op.od
                });
              }
              break;
            case "description":
              if (op.p[1] !== 0) {
                return;
              }
              if (!(op.si && op.sd)) {
                return;
              }
              return this._emit("setDescription", {
                description: op.si,
                old_description: op.sd
              });
            case "tags":
              if (!(op.li || op.ld)) {
                return;
              }
              if (op.p.length !== 2) {
                return;
              }
              if (op.li) {
                return this._emit("tagAdd", {
                  tagName: op.li,
                  index: op.p[1]
                });
              } else if (op.ld) {
                return this._emit("tagRemove", {
                  tagName: op.ld,
                  index: op.p[2]
                });
              }
              break;
            case "files":
              if (op.p.length === 2) {
                if (op.li) {
                  return this._emit("fileCreate", {
                    filename: op.li.filename,
                    index: op.p[1],
                    content: op.li.content
                  });
                } else if (op.ld) {
                  return this._emit("fileRemove", {
                    filename: op.ld.filename,
                    index: op.p[1],
                    content: op.ld.content
                  });
                }
              } else if (op.p[2] === "filename") {
                return this._emit("fileRename", {
                  filename: op.oi,
                  index: op.p[1],
                  old_filename: op.od
                });
              } else if (op.p[2] === "content") {
                filename = snapshot.files[op.p[1]].filename;
                if (op.si) {
                  this._emit("textInsert", {
                    filename: filename,
                    index: op.p[1],
                    text: op.si,
                    offset: op.p[3]
                  });
                }
                if (op.sd) {
                  return this._emit("textRemove", {
                    filename: filename,
                    index: op.p[1],
                    text: op.sd,
                    offset: op.p[3]
                  });
                }
              }
          }
        }
      };

      SessionClient.prototype._emit = function(eventName, e) {
        var listener, snapshot, _i, _len, _ref, _results;
        snapshot = this.getSnapshot();
        e.eventName = eventName;
        if (this.listeners[eventName]) {
          _ref = this.listeners[eventName];
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            listener = _ref[_i];
            _results.push(listener(e, snapshot));
          }
          return _results;
        }
      };

      SessionClient.prototype.getCursorFileIndex = function() {
        return this.session.snapshot.cursor.fileIndex;
      };

      SessionClient.prototype.getCursorTextOffset = function() {
        return this.session.snapshot.cursor.textOffset;
      };

      SessionClient.prototype.getDescription = function() {
        return this.session.snapshot.description;
      };

      SessionClient.prototype.getFileIndex = function(filename) {
        var file, idx, _i, _len, _ref;
        _ref = this.session.snapshot.files;
        for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
          file = _ref[idx];
          if (file.filename === filename) {
            return idx;
          }
        }
        return -1;
      };

      SessionClient.prototype.getFileByIndex = function(idx) {
        if (angular.isString(idx)) {
          idx = this.getFileIndex(idx);
        }
        return this.session.snapshot.files[idx];
      };

      SessionClient.prototype.getFile = function(filename) {
        var file, _i, _len, _ref;
        _ref = this.session.snapshot.files;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          file = _ref[_i];
          if (file.filename === filename) {
            return file;
          }
        }
      };

      SessionClient.prototype.getNumFiles = function() {
        var _ref;
        return ((_ref = this.session.snapshot.files) != null ? _ref.length : void 0) || 0;
      };

      SessionClient.prototype.getNumTags = function() {
        var _ref;
        return ((_ref = this.session.snapshot.tags) != null ? _ref.length : void 0) || 0;
      };

      SessionClient.prototype.getSnapshot = function() {
        return this.session.snapshot;
      };

      SessionClient.prototype.getTagIndex = function(tagName) {
        var idx, tag, _i, _len, _ref;
        _ref = this.session.snapshot.tags;
        for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
          tag = _ref[idx];
          if (tag === tagName) {
            return idx;
          }
        }
        return -1;
      };

      SessionClient.prototype.hasFile = function(filename) {
        return this.getFileIndex(filename) >= 0;
      };

      SessionClient.prototype.hasFileIndex = function(idx) {
        return this.getFileByIndex(idx) != null;
      };

      SessionClient.prototype.hasTag = function(tagName) {
        return this.getTagIndex(tagName) >= 0;
      };

      SessionClient.prototype.isValidTag = function(tagName) {
        return /^[-_a-z0-9\.\[\]]+$/i.test(tagName);
      };

      SessionClient.prototype.isValidFile = function(file) {
        return this.isValidFilename(file.filename) && angular.isString(file.content);
      };

      SessionClient.prototype.isValidFilename = function(filename) {
        return /^[-_a-z0-9\.\[\]]+$/i.test(filename);
      };

      SessionClient.prototype.reset = function(json) {
        var file, tagName, _i, _j, _len, _len1, _ref, _ref1;
        if (json == null) {
          json = {};
        }
        json.description || (json.description = "");
        json.tags || (json.tags = []);
        json.cursor || (json.cursor = {
          fileIndex: 0,
          textOffset: 0
        });
        if (!angular.isString(json.description)) {
          throw new Error("Reset failed. Description must be a string.");
        }
        if (!angular.isArray(json.tags)) {
          throw new Error("Reset failed. Tags must be an array.");
        }
        _ref = json.tags;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          tagName = _ref[_i];
          if (!this.isValidTag(tagName)) {
            throw new Error("Reset failed. Invalid tag: " + tagName + ".");
          }
        }
        if (!angular.isArray(json.files)) {
          throw new Error("Reset failed. Files must be an array.");
        }
        _ref1 = json.files;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          file = _ref1[_j];
          if (!this.isValidFile(file)) {
            throw new Error("Reset failed. Invalid file: " + (JSON.stringify(file)) + ".");
          }
        }
        if (!json.files.length) {
          throw new Error("Reset failed. There must be at least one file.");
        }
        return this._applyOp({
          p: [],
          od: angular.copy(this.getSnapshot()),
          oi: json
        });
      };

      SessionClient.prototype.cursorSetFile = function(filename) {
        var idx;
        if (!this.hasFile(filename)) {
          throw new Error("Unable set the active file. File does not exist: " + filename);
        }
        idx = this.getFileIndex(filename);
        return this._applyOp({
          p: ["cursor", "fileIndex"],
          od: this.getCursorFileIndex(),
          oi: idx
        });
      };

      SessionClient.prototype.cursorSetIndex = function(idx) {
        if (!this.hasFileIndex(idx)) {
          throw new Error("Unable set the active file. File does not exist: " + filename);
        }
        return this._applyOp({
          p: ["cursor", "fileIndex"],
          od: this.getCursorFileIndex(),
          oi: idx
        });
      };

      SessionClient.prototype.cursorSetOffset = function(offset) {
        return this._applyOp({
          p: ["cursor", "textOffset"],
          od: this.getCursorTextOffset(),
          oi: offset
        });
      };

      SessionClient.prototype.setDescription = function(description) {
        if (description == null) {
          description = "";
        }
        return this._applyOp({
          p: ["description", 0],
          sd: this.getDescription(),
          si: description
        });
      };

      SessionClient.prototype.fileCreate = function(filename, content) {
        var idx;
        if (content == null) {
          content = "";
        }
        if (!this.isValidFilename(filename)) {
          throw new Error("Unable to create file. Invalid filename: " + filename);
        }
        if (this.hasFile(filename)) {
          throw new Error("Unable to create file. File already exists: " + filename);
        }
        idx = this.getNumFiles();
        return this._applyOp({
          p: ["files", idx],
          li: {
            filename: filename,
            content: content
          }
        });
      };

      SessionClient.prototype.fileRename = function(filename, new_filename) {
        var idx;
        if (!this.isValidFilename(new_filename)) {
          throw new Error("Unable to create file. Invalid filename: " + new_filename);
        }
        if (!this.hasFile(filename)) {
          throw new Error("Unable to rename file. File does not exist: " + filename);
        }
        if (this.hasFile(new_filename)) {
          throw new Error("Unable to rename file. A file already exists named: " + new_filename);
        }
        idx = this.getFileIndex(filename);
        return this._applyOp({
          p: ["files", idx, "filename"],
          od: filename,
          oi: new_filename
        });
      };

      SessionClient.prototype.fileRemove = function(filename) {
        var idx;
        if (!this.hasFile(filename)) {
          throw new Error("Unable to remove file. File does not exist: " + filename);
        }
        if (this.getNumFiles() <= 1) {
          throw new Error("Unable to remove file. You can not remove all files.");
        }
        idx = this.getFileIndex(filename);
        this.cursorSetIndex(0);
        return this._applyOp({
          p: ["files", idx],
          ld: this.getFile(filename)
        });
      };

      SessionClient.prototype.textInsert = function(filename, offset, text) {
        var idx;
        if (!this.hasFile(filename)) {
          throw new Error("Unable to insert text. File does not exist: " + filename);
        }
        idx = this.getFileIndex(filename);
        return this._applyOp({
          p: ["files", idx, "content", offset],
          si: text
        });
      };

      SessionClient.prototype.textRemove = function(filename, offset, text) {
        var idx;
        if (!this.hasFile(filename)) {
          throw new Error("Unable to remove text. File does not exist: " + filename);
        }
        idx = this.getFileIndex(filename);
        return this._applyOp({
          p: ["files", idx, "content", offset],
          sd: text
        });
      };

      SessionClient.prototype.tagAdd = function(tagName) {
        var idx;
        if (!this.isValidTag(tagName)) {
          throw new Error("Unable to add tag. Invalid tag: " + tagName);
        }
        if (this.hasTag(tagName)) {
          throw new Error("Unable to add tag. Tag already exists: " + tagName);
        }
        idx = this.getNumTags();
        return this._applyOp({
          p: ["tags", idx],
          li: tagName
        });
      };

      SessionClient.prototype.tagRemove = function(tagName) {
        var idx;
        if (!this.hasTag(tagName)) {
          throw new Error("Unable to remove tag. Tag not found: " + tagName);
        }
        idx = this.getTagIndex(tagName);
        return this._applyOp({
          p: ["tags", idx],
          ld: tagName
        });
      };

      return SessionClient;

    })();

    function Session() {
      this.$clients = {};
      this.snapshot = {};
      this.iface = this.createClient("session");
      this.iface.reset({
        files: [
          {
            filename: "index.html",
            content: ""
          }
        ]
      });
    }

    Session.prototype.createClient = function(clientName) {
      var session;
      if (this.$clients[clientName]) {
        throw new Error("Unable to create client. Client already created: " + clientName + ".");
      }
      session = this;
      return this.$clients[clientName] = new SessionClient(clientName, session);
    };

    Session.prototype.applyOps = function(sourceClientName, ops) {
      var client, clientName, op, postSnapshot, _i, _len, _ref, _results;
      postSnapshot = ottypes.json0.apply(this.snapshot, ops);
      for (_i = 0, _len = ops.length; _i < _len; _i++) {
        op = ops[_i];
        console.log("[OT] op", op);
      }
      console.log("[OT] snapshot", angular.copy(this.snapshot));
      if (this.snapshot !== postSnapshot) {
        angular.copy(postSnapshot, this.snapshot);
      }
      _ref = this.$clients;
      _results = [];
      for (clientName in _ref) {
        client = _ref[clientName];
        if (clientName !== sourceClientName) {
          _results.push((function() {
            var _j, _len1, _results1;
            _results1 = [];
            for (_j = 0, _len1 = ops.length; _j < _len1; _j++) {
              op = ops[_j];
              _results1.push(client._handleOp(sourceClientName, op, this.snapshot));
            }
            return _results1;
          }).call(this));
        }
      }
      return _results;
    };

    return Session;

  })());

}).call(this);


},{"../../vendor/ottypes/webclient/json0.uncompressed.js":11}],7:[function(require,module,exports){
(function() {
  var module;

  module = angular.module("plunker.service.settings", []);

  module.service("settings", [
    function() {
      var e, saved, settings;
      settings = {
        previewer: {
          delay: 1000,
          auto_refresh: true
        },
        editor: {
          tab_size: 2,
          soft_tabs: true,
          theme: "textmate",
          wrap: {
            range: {
              min: 0,
              max: 80
            },
            enabled: false
          }
        }
      };
      if (typeof localStorage !== "undefined" && localStorage !== null) {
        if (saved = localStorage.getItem("plnkr_settings")) {
          try {
            saved = JSON.parse(saved);
          } catch (_error) {
            e = _error;
            saved = {};
          }
        }
        setInterval(function() {
          return localStorage.setItem("plnkr_settings", JSON.stringify(settings));
        }, 2000);
      }
      return angular.extend(settings, saved);
    }
  ]);

}).call(this);


},{}],8:[function(require,module,exports){
(function() {
  var module;

  module = angular.module("plunker.service.types", []);

  module.factory("types", function() {
    var name, type, types;
    types = {
      html: {
        regex: /\.html$/i,
        mime: "text/html"
      },
      javascript: {
        regex: /\.js$/i,
        mime: "text/javascript"
      },
      coffee: {
        regex: /\.coffee$/i,
        mime: "text/coffee"
      },
      css: {
        regex: /\.css$/i,
        mime: "text/css"
      },
      text: {
        regex: /\.txt$/,
        mime: "text/plain"
      }
    };
    for (name in types) {
      type = types[name];
      type.name = name;
    }
    return {
      types: types,
      getByFilename: function(filename) {
        var mode;
        for (name in types) {
          mode = types[name];
          if (mode.regex.test(filename)) {
            return mode;
          }
        }
        return types.text;
      }
    };
  });

}).call(this);


},{}],9:[function(require,module,exports){
(function() {
  var module;

  module = angular.module("plunker.service.url", []);

  module.constant("url", _plunker.url);

}).call(this);


},{}],10:[function(require,module,exports){
/**
 * Operative
 * ---
 * Operative is a small JS utility for seamlessly creating Web Worker scripts.
 * ---
 * @author James Padolsey http://james.padolsey.com
 * @repo http://github.com/padolsey/operative
 * @version 0.2.1
 * @license MIT
 */
(function() {

	if (typeof window == 'undefined' && self.importScripts) {
		// I'm a worker! Run the boiler-script:
		// (Operative itself is called in IE10 as a worker,
		//  to avoid SecurityErrors)
		workerBoilerScript();
		return;
	}

	var slice = [].slice;
	var hasOwn = {}.hasOwnProperty;

	var scripts = document.getElementsByTagName('script');
	var opScript = scripts[scripts.length - 1];
	var opScriptURL = /operative/.test(opScript.src) && opScript.src;

	// Default base URL (to be prepended to relative dependency URLs)
	// is current page's parent dir:
	var baseURL = (
		location.protocol + '//' +
		location.hostname +
		(location.port?':'+location.port:'') +
		location.pathname
	).replace(/[^\/]+$/, '');

	var URL = window.URL || window.webkitURL;
	var BlobBuilder = window.BlobBuilder || window.WebKitBlobBuilder || window.MozBlobBuilder;

	var workerViaBlobSupport = (function() {
		try {
			new Worker(makeBlobURI(';'));
		} catch(e) {
			return false;
		}
		return true;
	}());

	/**
	 * Provide Object.create shim
	 */
	var objCreate = Object.create || function(o) {
		function F() {}
		F.prototype = o;
		return new F();
	};

	function makeBlobURI(script) {
		var blob;

		try {
			blob = new Blob([script], { type: 'text/javascript' });
		} catch (e) { 
			blob = new BlobBuilder();
			blob.append(script);
			blob = blob.getBlob();
		}

		return URL.createObjectURL(blob);
	}

	// Indicates whether operatives will run within workers:
	operative.hasWorkerSupport = !!window.Worker;

	operative.Promise = window.Promise;

	// Expose:
	if (typeof module !== 'undefined' && module.exports) {
		module.exports = operative;
	} else {
		window.operative = operative;
	}
	

	operative.setSelfURL = function(url) {
		opScriptURL = url;
	};

	operative.setBaseURL = function(base) {
		baseURL = base;
	};

	operative.getBaseURL = function() {
		return baseURL;
	};

	/**
	 * Operative: Exposed Operative Constructor
	 * @param {Object} module Object containing methods/properties
	 */
	function Operative(module, dependencies) {

		var _self = this;

		module.get = module.get || function(prop) {
			return this[prop];
		};

		module.set = module.set || function(prop, value) {
			return this[prop] = value;
		};

		this._curToken = 0;
		this._queue = [];

		this.isDestroyed = false;
		this.isContextReady = false;

		this.module = module;
		this.dependencies = dependencies || [];

		this.dataProperties = {};
		this.api = {};
		this.callbacks = {};
		this.deferreds = {};

		this._fixDependencyURLs();
		this._setup();

		for (var methodName in module) {
			if (hasOwn.call(module, methodName)) {
				this._createExposedMethod(methodName);
			}
		}

		this.api.__operative__ = this;

		// Provide the instance's destroy method on the exposed API:
		this.api.destroy = function() {
			return _self.destroy();
		};

	}

	Operative.prototype = {

		_marshal: function(v) {
			return v;
		},

		_demarshal: function(v) {
			return v;
		},

		_enqueue: function(fn) {
			this._queue.push(fn);
		},

		_fixDependencyURLs: function() {
			var deps = this.dependencies;
			for (var i = 0, l = deps.length; i < l; ++i) {
				var dep = deps[i];
				if (!/\/\//.test(dep)) {
					deps[i] = dep.replace(/^\/?/, baseURL);
				}
			}
		},

		_dequeueAll: function() {
			for (var i = 0, l = this._queue.length; i < l; ++i) {
				this._queue[i].call(this);
			}
			this._queue = [];
		},

		_buildContextScript: function(boilerScript) {

			var script = [];
			var module = this.module;
			var dataProperties = this.dataProperties;
			var property;

			for (var i in module) {
				property = module[i];
				if (typeof property == 'function') {
					script.push('   self["' + i.replace(/"/g, '\\"') + '"] = ' + property.toString() + ';');
				} else {
					dataProperties[i] = property;
				}
			}

			return script.join('\n') + (
				boilerScript ? '\n(' + boilerScript.toString() + '());' : ''
			);

		},

		_createExposedMethod: function(methodName) {

			var self = this;

			this.api[methodName] = function() {

				if (self.isDestroyed) {
					throw new Error('Operative: Cannot run method. Operative has already been destroyed');
				}

				var token = ++self._curToken;
				var args = slice.call(arguments);
				var cb = typeof args[args.length - 1] == 'function' && args.pop();

				if (!cb && !operative.Promise) {
					throw new Error(
						'Operative: No callback has been passed. Assumed that you want a promise. ' +
						'But `operative.Promise` is null. Please provide Promise polyfill/lib.'
					);
				}

				if (cb) {

					self.callbacks[token] = cb;

					// Ensure either context runs the method async:
					setTimeout(function() {
						runMethod();
					}, 1);

				} else if (operative.Promise) {

					// No Callback -- Promise used:

					return new operative.Promise(function(deferred) {
						deferred.fulfil = deferred.fulfill;
						self.deferreds[token] = deferred;
						runMethod();
					});

				}

				function runMethod() {
					if (self.isContextReady) {
						self._runMethod(methodName, token, args);
					} else {
						self._enqueue(runMethod);
					}
				}

			};

		},

		destroy: function() {
			this.isDestroyed = true;
		}
	};


	/**
	 * Operative Worker
	 */
	Operative.Worker = function Worker(module) {
		this._msgQueue = [];
		Operative.apply(this, arguments);
	};

	var WorkerProto = Operative.Worker.prototype = objCreate(Operative.prototype);

	WorkerProto._onWorkerMessage = function(e) {
		var data = e.data;

		if (typeof data === 'string' && data.indexOf('pingback') === 0) {
			if (data === 'pingback:structuredCloningSupport=NO') {
				// No structuredCloningSupport support (marshal JSON from now on):
				this._marshal = function(o) { return JSON.stringify(o); };
				this._demarshal = function(o) { return JSON.parse(o); };
			}

			this.isContextReady = true;
			this._postMessage({
				definitions: this.dataProperties
			});
			this._dequeueAll();
			return;

		}

		data = this._demarshal(data);

		switch (data.cmd) {
			case 'console':
				window.console && window.console[data.method].apply(window.console, data.args);
				break;
			case 'result':

				var callback = this.callbacks[data.token];
				var deferred = this.deferreds[data.token];

				delete this.callbacks[data.token];
				delete this.deferreds[data.token];

				var deferredAction = data.result && data.result.isDeferred && data.result.action;

				if (deferred && deferredAction) {
					deferred[deferredAction](data.result.args[0]);
				} else if (callback) {
					callback.apply(this, data.result.args);
				}

				break;
		}
	};

	WorkerProto._setup = function() {
		var self = this;

		var worker;
		var script = this._buildContextScript(
			// The script is not included if we're Eval'ing this file directly:
			workerViaBlobSupport ? workerBoilerScript : ''
		);

		if (this.dependencies.length) {
			script = 'importScripts("' + this.dependencies.join('", "') + '");\n' + script;
		}

		if (workerViaBlobSupport) {
			worker = this.worker = new Worker( makeBlobURI(script) );
		}  else {
			if (!opScriptURL) {
				throw new Error('Operaritve: No operative.js URL available. Please set via operative.setSelfURL(...)');
			}
			worker = this.worker = new Worker( opScriptURL );
			// Marshal-agnostic initial message is boiler-code:
			// (We don't yet know if structured-cloning is supported so we send a string)
			worker.postMessage('EVAL|' + script);
		}

		worker.postMessage(['PING']); // Initial PING

		worker.addEventListener('message', function(e) {
			self._onWorkerMessage(e);
		});
	};

	WorkerProto._postMessage = function(msg) {
		return this.worker.postMessage(this._marshal(msg));
	};

	WorkerProto._runMethod = function(methodName, token, args) {
		this._postMessage({
			method: methodName,
			args: args,
			token: token
		});
	};

	WorkerProto.destroy = function() {
		this.worker.terminate();
		Operative.prototype.destroy.call(this);
	};


	/**
	 * Operative IFrame
	 */
	Operative.Iframe = function Iframe(module) {
		Operative.apply(this, arguments);
	};

	var IframeProto = Operative.Iframe.prototype = objCreate(Operative.prototype);

	var _loadedMethodNameI = 0;

	IframeProto._setup = function() {

		var self = this;
		var loadedMethodName = '__operativeIFrameLoaded' + ++_loadedMethodNameI;

		this.module.isWorker = false;

		var iframe = this.iframe = document.body.appendChild(
			document.createElement('iframe')
		);

		iframe.style.display = 'none';

		var iWin = this.iframeWindow = iframe.contentWindow;
		var iDoc = iWin.document;

		// Cross browser (tested in IE8,9) way to call method from within
		// IFRAME after all <Script>s have loaded:
		window[loadedMethodName] = function() {

			window[loadedMethodName] = null;

			var script = iDoc.createElement('script');
			var js = self._buildContextScript(iframeBoilerScript);

			if (script.text !== void 0) {
				script.text = js;
			} else {
				script.innerHTML = js;
			}

			iDoc.documentElement.appendChild(script);

			for (var i in self.dataProperties) {
				iWin[i] = self.dataProperties[i];
			}

			self.isContextReady = true;
			self._dequeueAll();

		};

		iDoc.open();
		if (this.dependencies.length) {
			iDoc.write(
				'<script src="' + this.dependencies.join('"></script><script src="') + '"></script>'
			);
		}
		// Place <script> at bottom to tell parent-page when dependencies are loaded:
		iDoc.write('<script>window.top.' + loadedMethodName + '();</script>');
		iDoc.close();

	};

	IframeProto._runMethod = function(methodName, token, args) {
		var self = this;
		var callback = this.callbacks[token];
		var deferred = this.deferreds[token];
		delete this.callbacks[token];
		delete this.deferreds[token];
		this.iframeWindow.__run__(methodName, args, function() {
			var cb = callback;
			if (cb) {
				callback = null;
				cb.apply(self, arguments);
			} else {
				throw new Error('Operative: You have already returned.');
			}
		}, deferred);
	};

	IframeProto.destroy = function() {
		this.iframe.parentNode.removeChild(this.iframe);
		Operative.prototype.destroy.call(this);
	};

	operative.Operative = Operative;

	/**
	 * Exposed operative factory
	 */
	function operative(module, dependencies) {

		var OperativeContext = operative.hasWorkerSupport ?
			Operative.Worker : Operative.Iframe;

		if (typeof module == 'function') {
			// Allow a single function to be passed.
			var o = new OperativeContext({ main: module }, dependencies);
			return function() {
				return o.api.main.apply(o, arguments);
			};
		}

		return new OperativeContext(module, dependencies).api;

	}

/**
 * The boilerplate for the Iframe Context
 * NOTE:
 *  this'll be executed within an iframe, not here.
 *  Indented @ Zero to make nicer debug code within worker
 */
function iframeBoilerScript() {

	// Called from parent-window:
	window.__run__ = function(methodName, args, cb, deferred) {

		var isAsync = false;
		var isDeferred = false;

		window.async = function() {
			isAsync = true;
			return cb;
		};

		window.deferred = function() {
			isDeferred = true;
			return deferred;
		};

		if (cb) {
			args.push(cb);
		}

		var result = window[methodName].apply(window, args);

		window.async = function() {
			throw new Error('Operative: async() called at odd time');
		};

		window.deferred = function() {
			throw new Error('Operative: deferred() called at odd time');
		};


		if (!isDeferred && !isAsync && result !== void 0) {
			// Deprecated direct-returning as of 0.2.0
			cb(result);
		}
	};
}

/**
 * The boilerplate for the Worker Blob
 * NOTE:
 *  this'll be executed within an iframe, not here.
 *  Indented @ Zero to make nicer debug code within worker
 */
function workerBoilerScript() {

	var postMessage = self.postMessage;
	var structuredCloningSupport = null;

	self.console = {};
	self.isWorker = true;

	// Provide basic console interface:
	['log', 'debug', 'error', 'info', 'warn', 'time', 'timeEnd'].forEach(function(meth) {
		self.console[meth] = function() {
			postMessage({
				cmd: 'console',
				method: meth,
				args: [].slice.call(arguments)
			});
		};
	});

	self.addEventListener('message', function(e) {

		var data = e.data;

		if (typeof data == 'string' && data.indexOf('EVAL|') === 0) {
			eval(data.substring(5));
			return;
		}

		if (structuredCloningSupport == null) {

			// e.data of ['PING'] (An array) indicates transferrableObjSupport
			// e.data of '"PING"' (A string) indicates no support (Array has been serialized)
			structuredCloningSupport = e.data[0] === 'PING';

			// Pingback to parent page:
			self.postMessage(
				structuredCloningSupport ?
					'pingback:structuredCloningSupport=YES' :
					'pingback:structuredCloningSupport=NO'
			);

			if (!structuredCloningSupport) {
				postMessage = function(msg) {
					// Marshal before sending
					return self.postMessage(JSON.stringify(msg));
				};
			}

			return;
		}

		if (!structuredCloningSupport) {
			// Demarshal:
			data = JSON.parse(data);
		}

		var defs = data.definitions;
		var isDeferred = false;
		var isAsync = false;
		var args = data.args;

		if (defs) {
			// Initial definitions:
			for (var i in defs) {
				self[i] = defs[i];
			}
			return;
		}

		args.push(function() {
			// Callback function to be passed to operative method
			returnResult({
				args: [].slice.call(arguments)
			});
		});

		self.async = function() { // Async deprecated as of 0.2.0
			isAsync = true;
			return function() { returnResult({ args: [].slice.call(arguments) }); };
		};

		self.deferred = function() {
			isDeferred = true;
			var def = {};
			function fulfill(r) {
				returnResult({
					isDeferred: true,
					action: 'fulfill',
					args: [r]
				});
				return def;
			}
			function reject(r) {
				returnResult({
					isDeferred: true,
					action: 'reject',
					args: [r]
				});
			}
			def.fulfil = def.fulfill = fulfill;
			def.reject = reject;
			return def;
		};

		// Call actual operative method:
		var result = self[data.method].apply(self, args);

		if (!isDeferred && !isAsync && result !== void 0) {
			// Deprecated direct-returning as of 0.2.0
			returnResult({
				args: [result]
			});
		}

		self.deferred = function() {
			throw new Error('Operative: deferred() called at odd time');
		};

		self.async = function() { // Async deprecated as of 0.2.0
			throw new Error('Operative: async() called at odd time');
		};

		function returnResult(res) {
			postMessage({
				cmd: 'result',
				token: data.token,
				result: res
			});
			// Override with error-thrower if we've already returned:
			returnResult = function() {
				throw new Error('Operative: You have already returned.');
			};
		}
	});
}

}());
},{}],11:[function(require,module,exports){
// This is a prelude which comes before the JS blob of each JS type for the web.
(function(){
  var module = {exports:{}};
  var exports = module.exports;

// These methods let you build a transform function from a transformComponent
// function for OT types like JSON0 in which operations are lists of components
// and transforming them reqreuires N^2 work. I find it kind of nasty that I need
// this, but I'm not really sure what a better solution is. Maybe I should do
// this automatically to types that don't have a compose function defined.

// Add transform and transformX functions for an OT type which has
// transformComponent defined.  transformComponent(destination array,
// component, other component, side)
exports._bootstrapTransform = function(type, transformComponent, checkValidOp, append) {
  var transformComponentX = function(left, right, destLeft, destRight) {
    transformComponent(destLeft, left, right, 'left');
    transformComponent(destRight, right, left, 'right');
  };

  var transformX = type.transformX = function(leftOp, rightOp) {
    checkValidOp(leftOp);
    checkValidOp(rightOp);
    var newRightOp = [];

    for (var i = 0; i < rightOp.length; i++) {
      var rightComponent = rightOp[i];

      // Generate newLeftOp by composing leftOp by rightComponent
      var newLeftOp = [];
      var k = 0;
      while (k < leftOp.length) {
        var nextC = [];
        transformComponentX(leftOp[k], rightComponent, newLeftOp, nextC);
        k++;

        if (nextC.length === 1) {
          rightComponent = nextC[0];
        } else if (nextC.length === 0) {
          for (var j = k; j < leftOp.length; j++) {
            append(newLeftOp, leftOp[j]);
          }
          rightComponent = null;
          break;
        } else {
          // Recurse.
          var pair = transformX(leftOp.slice(k), nextC);
          for (var l = 0; l < pair[0].length; l++) {
            append(newLeftOp, pair[0][l]);
          }
          for (var r = 0; r < pair[1].length; r++) {
            append(newRightOp, pair[1][r]);
          }
          rightComponent = null;
          break;
        }
      }

      if (rightComponent != null) {
        append(newRightOp, rightComponent);
      }
      leftOp = newLeftOp;
    }
    return [leftOp, newRightOp];
  };

  // Transforms op with specified type ('left' or 'right') by otherOp.
  type.transform = type['transform'] = function(op, otherOp, type) {
    if (!(type === 'left' || type === 'right'))
      throw new Error("type must be 'left' or 'right'");

    if (otherOp.length === 0) return op;

    if (op.length === 1 && otherOp.length === 1)
      return transformComponent([], op[0], otherOp[0], type);

    if (type === 'left')
      return transformX(op, otherOp)[0];
    else
      return transformX(otherOp, op)[1];
  };
};
// DEPRECATED!
//
// This type works, but is not exported, and will be removed in a future version of this library.


// A simple text implementation
//
// Operations are lists of components.
// Each component either inserts or deletes at a specified position in the document.
//
// Components are either:
//  {i:'str', p:100}: Insert 'str' at position 100 in the document
//  {d:'str', p:100}: Delete 'str' at position 100 in the document
//
// Components in an operation are executed sequentially, so the position of components
// assumes previous components have already executed.
//
// Eg: This op:
//   [{i:'abc', p:0}]
// is equivalent to this op:
//   [{i:'a', p:0}, {i:'b', p:1}, {i:'c', p:2}]

// NOTE: The global scope here is shared with other sharejs files when built with closure.
// Be careful what ends up in your namespace.

var text = module.exports = {
  name: 'text0',
  uri: 'http://sharejs.org/types/textv0',
  create: function(initial) {
    if ((initial != null) && typeof initial !== 'string') {
      throw new Error('Initial data must be a string');
    }
    return initial || '';
  }
};

/** Insert s2 into s1 at pos. */
var strInject = function(s1, pos, s2) {
  return s1.slice(0, pos) + s2 + s1.slice(pos);
};

/** Check that an operation component is valid. Throws if its invalid. */
var checkValidComponent = function(c) {
  if (typeof c.p !== 'number')
    throw new Error('component missing position field');

  if ((typeof c.i === 'string') === (typeof c.d === 'string'))
    throw new Error('component needs an i or d field');

  if (c.p < 0)
    throw new Error('position cannot be negative');
};

/** Check that an operation is valid */
var checkValidOp = function(op) {
  for (var i = 0; i < op.length; i++) {
    checkValidComponent(op[i]);
  }
};

/** Apply op to snapshot */
text.apply = function(snapshot, op) {
  var deleted;

  checkValidOp(op);
  for (var i = 0; i < op.length; i++) {
    var component = op[i];
    if (component.i != null) {
      snapshot = strInject(snapshot, component.p, component.i);
    } else {
      deleted = snapshot.slice(component.p, component.p + component.d.length);
      if (component.d !== deleted)
        throw new Error("Delete component '" + component.d + "' does not match deleted text '" + deleted + "'");

      snapshot = snapshot.slice(0, component.p) + snapshot.slice(component.p + component.d.length);
    }
  }
  return snapshot;
};

/**
 * Append a component to the end of newOp. Exported for use by the random op
 * generator and the JSON0 type.
 */
var append = text._append = function(newOp, c) {
  if (c.i === '' || c.d === '') return;

  if (newOp.length === 0) {
    newOp.push(c);
  } else {
    var last = newOp[newOp.length - 1];

    if (last.i != null && c.i != null && last.p <= c.p && c.p <= last.p + last.i.length) {
      // Compose the insert into the previous insert
      newOp[newOp.length - 1] = {i:strInject(last.i, c.p - last.p, c.i), p:last.p};

    } else if (last.d != null && c.d != null && c.p <= last.p && last.p <= c.p + c.d.length) {
      // Compose the deletes together
      newOp[newOp.length - 1] = {d:strInject(c.d, last.p - c.p, last.d), p:c.p};

    } else {
      newOp.push(c);
    }
  }
};

/** Compose op1 and op2 together */
text.compose = function(op1, op2) {
  checkValidOp(op1);
  checkValidOp(op2);
  var newOp = op1.slice();
  for (var i = 0; i < op2.length; i++) {
    append(newOp, op2[i]);
  }
  return newOp;
};

/** Clean up an op */
text.normalize = function(op) {
  var newOp = [];

  // Normalize should allow ops which are a single (unwrapped) component:
  // {i:'asdf', p:23}.
  // There's no good way to test if something is an array:
  // http://perfectionkills.com/instanceof-considered-harmful-or-how-to-write-a-robust-isarray/
  // so this is probably the least bad solution.
  if (op.i != null || op.p != null) op = [op];

  for (var i = 0; i < op.length; i++) {
    var c = op[i];
    if (c.p == null) c.p = 0;

    append(newOp, c);
  }

  return newOp;
};

// This helper method transforms a position by an op component.
//
// If c is an insert, insertAfter specifies whether the transform
// is pushed after the insert (true) or before it (false).
//
// insertAfter is optional for deletes.
var transformPosition = function(pos, c, insertAfter) {
  // This will get collapsed into a giant ternary by uglify.
  if (c.i != null) {
    if (c.p < pos || (c.p === pos && insertAfter)) {
      return pos + c.i.length;
    } else {
      return pos;
    }
  } else {
    // I think this could also be written as: Math.min(c.p, Math.min(c.p -
    // otherC.p, otherC.d.length)) but I think its harder to read that way, and
    // it compiles using ternary operators anyway so its no slower written like
    // this.
    if (pos <= c.p) {
      return pos;
    } else if (pos <= c.p + c.d.length) {
      return c.p;
    } else {
      return pos - c.d.length;
    }
  }
};

// Helper method to transform a cursor position as a result of an op.
//
// Like transformPosition above, if c is an insert, insertAfter specifies
// whether the cursor position is pushed after an insert (true) or before it
// (false).
text.transformCursor = function(position, op, side) {
  var insertAfter = side === 'right';
  for (var i = 0; i < op.length; i++) {
    position = transformPosition(position, op[i], insertAfter);
  }

  return position;
};

// Transform an op component by another op component. Asymmetric.
// The result will be appended to destination.
//
// exported for use in JSON type
var transformComponent = text._tc = function(dest, c, otherC, side) {
  //var cIntersect, intersectEnd, intersectStart, newC, otherIntersect, s;

  checkValidComponent(c);
  checkValidComponent(otherC);

  if (c.i != null) {
    // Insert.
    append(dest, {i:c.i, p:transformPosition(c.p, otherC, side === 'right')});
  } else {
    // Delete
    if (otherC.i != null) {
      // Delete vs insert
      var s = c.d;
      if (c.p < otherC.p) {
        append(dest, {d:s.slice(0, otherC.p - c.p), p:c.p});
        s = s.slice(otherC.p - c.p);
      }
      if (s !== '')
        append(dest, {d: s, p: c.p + otherC.i.length});

    } else {
      // Delete vs delete
      if (c.p >= otherC.p + otherC.d.length)
        append(dest, {d: c.d, p: c.p - otherC.d.length});
      else if (c.p + c.d.length <= otherC.p)
        append(dest, c);
      else {
        // They overlap somewhere.
        var newC = {d: '', p: c.p};

        if (c.p < otherC.p)
          newC.d = c.d.slice(0, otherC.p - c.p);

        if (c.p + c.d.length > otherC.p + otherC.d.length)
          newC.d += c.d.slice(otherC.p + otherC.d.length - c.p);

        // This is entirely optional - I'm just checking the deleted text in
        // the two ops matches
        var intersectStart = Math.max(c.p, otherC.p);
        var intersectEnd = Math.min(c.p + c.d.length, otherC.p + otherC.d.length);
        var cIntersect = c.d.slice(intersectStart - c.p, intersectEnd - c.p);
        var otherIntersect = otherC.d.slice(intersectStart - otherC.p, intersectEnd - otherC.p);
        if (cIntersect !== otherIntersect)
          throw new Error('Delete ops delete different text in the same region of the document');

        if (newC.d !== '') {
          newC.p = transformPosition(newC.p, otherC);
          append(dest, newC);
        }
      }
    }
  }

  return dest;
};

var invertComponent = function(c) {
  return (c.i != null) ? {d:c.i, p:c.p} : {i:c.d, p:c.p};
};

// No need to use append for invert, because the components won't be able to
// cancel one another.
text.invert = function(op) {
  // Shallow copy & reverse that sucka.
  op = op.slice().reverse();
  for (var i = 0; i < op.length; i++) {
    op[i] = invertComponent(op[i]);
  }
  return op;
};

exports._bootstrapTransform(text, transformComponent, checkValidOp, append);

/*
 This is the implementation of the JSON OT type.

 Spec is here: https://github.com/josephg/ShareJS/wiki/JSON-Operations

 Note: This is being made obsolete. It will soon be replaced by the JSON2 type.
*/

/**
 * UTILITY FUNCTIONS
 */

/**
 * Checks if the passed object is an Array instance. Can't use Array.isArray
 * yet because its not supported on IE8.
 *
 * @param obj
 * @returns {boolean}
 */
var isArray = function(obj) {
  return Object.prototype.toString.call(obj) == '[object Array]';
};

/**
 * Clones the passed object using JSON serialization (which is slow).
 *
 * hax, copied from test/types/json. Apparently this is still the fastest way
 * to deep clone an object, assuming we have browser support for JSON.  @see
 * http://jsperf.com/cloning-an-object/12
 */
var clone = function(o) {
  return JSON.parse(JSON.stringify(o));
};

/**
 * Reference to the Text OT type. This is used for the JSON String operations.
 * @type {*}
 */
if (typeof text === 'undefined')
  var text = window.ottypes.text;

/**
 * JSON OT Type
 * @type {*}
 */
var json = { 
  name: 'json0',
  uri: 'http://sharejs.org/types/JSONv0'
};

json.create = function(data) {
  // Null instead of undefined if you don't pass an argument.
  return data === undefined ? null : data;
};

json.invertComponent = function(c) {
  var c_ = {p: c.p};

  if (c.si !== void 0) c_.sd = c.si;
  if (c.sd !== void 0) c_.si = c.sd;
  if (c.oi !== void 0) c_.od = c.oi;
  if (c.od !== void 0) c_.oi = c.od;
  if (c.li !== void 0) c_.ld = c.li;
  if (c.ld !== void 0) c_.li = c.ld;
  if (c.na !== void 0) c_.na = -c.na;

  if (c.lm !== void 0) {
    c_.lm = c.p[c.p.length-1];
    c_.p = c.p.slice(0,c.p.length-1).concat([c.lm]);
  }

  return c_;
};

json.invert = function(op) {
  var op_ = op.slice().reverse();
  var iop = [];
  for (var i = 0; i < op_.length; i++) {
    iop.push(json.invertComponent(op_[i]));
  }
  return iop;
};

json.checkValidOp = function(op) {
  for (var i = 0; i < op.length; i++) {
  if (!isArray(op[i].p))
    throw new Error('Missing path');
  }
};

json.checkList = function(elem) {
  if (!isArray(elem))
    throw new Error('Referenced element not a list');
};

json.checkObj = function(elem) {
  if (elem.constructor !== Object) {
    throw new Error("Referenced element not an object (it was " + JSON.stringify(elem) + ")");
  }
};

json.apply = function(snapshot, op) {
  json.checkValidOp(op);

  op = clone(op);

  var container = {
    data: snapshot
  };

  for (var i = 0; i < op.length; i++) {
    var c = op[i];

    var parent = null;
    var parentKey = null;
    var elem = container;
    var key = 'data';

    for (var j = 0; j < c.p.length; j++) {
      var p = c.p[j];

      parent = elem;
      parentKey = key;
      elem = elem[key];
      key = p;

      if (parent == null)
        throw new Error('Path invalid');
    }

    // Number add
    if (c.na !== void 0) {
      if (typeof elem[key] != 'number')
        throw new Error('Referenced element not a number');

      elem[key] += c.na;
    }

    // String insert
    else if (c.si !== void 0) {
      if (typeof elem != 'string')
        throw new Error('Referenced element not a string (it was '+JSON.stringify(elem)+')');

      parent[parentKey] = elem.slice(0,key) + c.si + elem.slice(key);
    }

    // String delete
    else if (c.sd !== void 0) {
      if (typeof elem != 'string')
        throw new Error('Referenced element not a string');

      if (elem.slice(key,key + c.sd.length) !== c.sd)
        throw new Error('Deleted string does not match');

      parent[parentKey] = elem.slice(0,key) + elem.slice(key + c.sd.length);
    }

    // List replace
    else if (c.li !== void 0 && c.ld !== void 0) {
      json.checkList(elem);
      // Should check the list element matches c.ld
      elem[key] = c.li;
    }

    // List insert
    else if (c.li !== void 0) {
      json.checkList(elem);
      elem.splice(key,0, c.li);
    }

    // List delete
    else if (c.ld !== void 0) {
      json.checkList(elem);
      // Should check the list element matches c.ld here too.
      elem.splice(key,1);
    }

    // List move
    else if (c.lm !== void 0) {
      json.checkList(elem);
      if (c.lm != key) {
        var e = elem[key];
        // Remove it...
        elem.splice(key,1);
        // And insert it back.
        elem.splice(c.lm,0,e);
      }
    }

    // Object insert / replace
    else if (c.oi !== void 0) {
      json.checkObj(elem);

      // Should check that elem[key] == c.od
      elem[key] = c.oi;
    }

    // Object delete
    else if (c.od !== void 0) {
      json.checkObj(elem);

      // Should check that elem[key] == c.od
      delete elem[key];
    }

    else {
      throw new Error('invalid / missing instruction in op');
    }
  }

  return container.data;
};

// Helper for incrementally applying an operation to a snapshot. Calls yield
// after each op component has been applied.
json.incrementalApply = function(snapshot, op, _yield) {
  for (var i = 0; i < op.length; i++) {
    var smallOp = [op[i]];
    snapshot = json.apply(snapshot, smallOp);
    // I'd just call this yield, but thats a reserved keyword. Bah!
    _yield(smallOp, snapshot);
  }
  
  return snapshot;
};

// Checks if two paths, p1 and p2 match.
var pathMatches = json.pathMatches = function(p1, p2, ignoreLast) {
  if (p1.length != p2.length)
    return false;

  for (var i = 0; i < p1.length; i++) {
    if (p1[i] !== p2[i] && (!ignoreLast || i !== p1.length - 1))
      return false;
  }

  return true;
};

var _convertToTextComponent = function(component) {
  var newC = {p: component.p[component.p.length - 1]};
  if (component.si != null) {
    newC.i = component.si;
  } else {
    newC.d = component.sd;
  }
  return newC;
};

json.append = function(dest,c) {
  c = clone(c);

  var last;

  if (dest.length != 0 && pathMatches(c.p, (last = dest[dest.length - 1]).p)) {
    if (last.na != null && c.na != null) {
      dest[dest.length - 1] = {p: last.p, na: last.na + c.na};
    } else if (last.li !== undefined && c.li === undefined && c.ld === last.li) {
      // insert immediately followed by delete becomes a noop.
      if (last.ld !== undefined) {
        // leave the delete part of the replace
        delete last.li;
      } else {
        dest.pop();
      }
    } else if (last.od !== undefined && last.oi === undefined && c.oi !== undefined && c.od === undefined) {
      last.oi = c.oi;
    } else if (last.oi !== undefined && c.od !== undefined) {
      // The last path component inserted something that the new component deletes (or replaces).
      // Just merge them.
      if (c.oi !== undefined) {
        last.oi = c.oi;
      } else if (last.od !== undefined) {
        delete last.oi;
      } else {
        // An insert directly followed by a delete turns into a no-op and can be removed.
        dest.pop();
      }
    } else if (c.lm !== undefined && c.p[c.p.length - 1] === c.lm) {
      // don't do anything
    } else {
      dest.push(c);
    }
  } else if (dest.length != 0 && pathMatches(c.p, last.p, true)) {
    if ((c.si != null || c.sd != null) && (last.si != null || last.sd != null)) {
      // Try to compose the string ops together using text's equivalent methods
      var textOp = [_convertToTextComponent(last)];
      text._append(textOp, _convertToTextComponent(c));
      
      // Then convert back.
      if (textOp.length !== 1) {
        dest.push(c);
      } else {
        var textC = textOp[0];
        last.p[last.p.length - 1] = textC.p;
        if (textC.i != null)
          last.si = textC.i;
        else
          last.sd = textC.d;
      }
    } else {
      dest.push(c);
    }
  } else {
    dest.push(c);
  }
};

json.compose = function(op1,op2) {
  json.checkValidOp(op1);
  json.checkValidOp(op2);

  var newOp = clone(op1);

  for (var i = 0; i < op2.length; i++) {
    json.append(newOp,op2[i]);
  }

  return newOp;
};

json.normalize = function(op) {
  var newOp = [];

  op = isArray(op) ? op : [op];

  for (var i = 0; i < op.length; i++) {
    var c = op[i];
    if (c.p == null) c.p = [];

    json.append(newOp,c);
  }

  return newOp;
};

// Returns true if an op at otherPath may affect an op at path
json.canOpAffectOp = function(otherPath,path) {
  if (otherPath.length === 0) return true;
  if (path.length === 0) return false;

  path = path.slice(0,path.length - 1);
  otherPath = otherPath.slice(0,otherPath.length - 1);

  for (var i = 0; i < otherPath.length; i++) {
    var p = otherPath[i];
    if (i >= path.length || p != path[i]) return false;
  }

  // Same
  return true;
};

// transform c so it applies to a document with otherC applied.
json.transformComponent = function(dest, c, otherC, type) {
  c = clone(c);

  if (c.na !== void 0)
    c.p.push(0);

  if (otherC.na !== void 0)
    otherC.p.push(0);

  var common;
  if (json.canOpAffectOp(otherC.p, c.p))
    common = otherC.p.length - 1;

  var common2;
  if (json.canOpAffectOp(c.p,otherC.p))
    common2 = c.p.length - 1;

  var cplength = c.p.length;
  var otherCplength = otherC.p.length;

  if (c.na !== void 0) // hax
    c.p.pop();

  if (otherC.na !== void 0)
    otherC.p.pop();

  if (otherC.na) {
    if (common2 != null && otherCplength >= cplength && otherC.p[common2] == c.p[common2]) {
      if (c.ld !== void 0) {
        var oc = clone(otherC);
        oc.p = oc.p.slice(cplength);
        c.ld = json.apply(clone(c.ld),[oc]);
      } else if (c.od !== void 0) {
        var oc = clone(otherC);
        oc.p = oc.p.slice(cplength);
        c.od = json.apply(clone(c.od),[oc]);
      }
    }
    json.append(dest,c);
    return dest;
  }

  // if c is deleting something, and that thing is changed by otherC, we need to
  // update c to reflect that change for invertibility.
  // TODO this is probably not needed since we don't have invertibility
  if (common2 != null && otherCplength > cplength && c.p[common2] == otherC.p[common2]) {
    if (c.ld !== void 0) {
      var oc = clone(otherC);
      oc.p = oc.p.slice(cplength);
      c.ld = json.apply(clone(c.ld),[oc]);
    } else if (c.od !== void 0) {
      var oc = clone(otherC);
      oc.p = oc.p.slice(cplength);
      c.od = json.apply(clone(c.od),[oc]);
    }
  }

  if (common != null) {
    var commonOperand = cplength == otherCplength;

    // transform based on otherC
    if (otherC.na !== void 0) {
      // this case is handled above due to icky path hax
    } else if (otherC.si !== void 0 || otherC.sd !== void 0) {
      // String op vs string op - pass through to text type
      if (c.si !== void 0 || c.sd !== void 0) {
        if (!commonOperand) throw new Error('must be a string?');

        // Convert an op component to a text op component so we can use the
        // text type's transform function
        var tc1 = _convertToTextComponent(c);
        var tc2 = _convertToTextComponent(otherC);

        var res = [];

        // actually transform
        text._tc(res, tc1, tc2, type);
        
        // .... then convert the result back into a JSON op again.
        for (var i = 0; i < res.length; i++) {
          // Text component
          var tc = res[i];
          // JSON component
          var jc = {p: c.p.slice(0, common)};
          jc.p.push(tc.p);

          if (tc.i != null) jc.si = tc.i;
          if (tc.d != null) jc.sd = tc.d;
          json.append(dest, jc);
        }
        return dest;
      }
    } else if (otherC.li !== void 0 && otherC.ld !== void 0) {
      if (otherC.p[common] === c.p[common]) {
        // noop

        if (!commonOperand) {
          return dest;
        } else if (c.ld !== void 0) {
          // we're trying to delete the same element, -> noop
          if (c.li !== void 0 && type === 'left') {
            // we're both replacing one element with another. only one can survive
            c.ld = clone(otherC.li);
          } else {
            return dest;
          }
        }
      }
    } else if (otherC.li !== void 0) {
      if (c.li !== void 0 && c.ld === undefined && commonOperand && c.p[common] === otherC.p[common]) {
        // in li vs. li, left wins.
        if (type === 'right')
          c.p[common]++;
      } else if (otherC.p[common] <= c.p[common]) {
        c.p[common]++;
      }

      if (c.lm !== void 0) {
        if (commonOperand) {
          // otherC edits the same list we edit
          if (otherC.p[common] <= c.lm)
            c.lm++;
          // changing c.from is handled above.
        }
      }
    } else if (otherC.ld !== void 0) {
      if (c.lm !== void 0) {
        if (commonOperand) {
          if (otherC.p[common] === c.p[common]) {
            // they deleted the thing we're trying to move
            return dest;
          }
          // otherC edits the same list we edit
          var p = otherC.p[common];
          var from = c.p[common];
          var to = c.lm;
          if (p < to || (p === to && from < to))
            c.lm--;

        }
      }

      if (otherC.p[common] < c.p[common]) {
        c.p[common]--;
      } else if (otherC.p[common] === c.p[common]) {
        if (otherCplength < cplength) {
          // we're below the deleted element, so -> noop
          return dest;
        } else if (c.ld !== void 0) {
          if (c.li !== void 0) {
            // we're replacing, they're deleting. we become an insert.
            delete c.ld;
          } else {
            // we're trying to delete the same element, -> noop
            return dest;
          }
        }
      }

    } else if (otherC.lm !== void 0) {
      if (c.lm !== void 0 && cplength === otherCplength) {
        // lm vs lm, here we go!
        var from = c.p[common];
        var to = c.lm;
        var otherFrom = otherC.p[common];
        var otherTo = otherC.lm;
        if (otherFrom !== otherTo) {
          // if otherFrom == otherTo, we don't need to change our op.

          // where did my thing go?
          if (from === otherFrom) {
            // they moved it! tie break.
            if (type === 'left') {
              c.p[common] = otherTo;
              if (from === to) // ugh
                c.lm = otherTo;
            } else {
              return dest;
            }
          } else {
            // they moved around it
            if (from > otherFrom) c.p[common]--;
            if (from > otherTo) c.p[common]++;
            else if (from === otherTo) {
              if (otherFrom > otherTo) {
                c.p[common]++;
                if (from === to) // ugh, again
                  c.lm++;
              }
            }

            // step 2: where am i going to put it?
            if (to > otherFrom) {
              c.lm--;
            } else if (to === otherFrom) {
              if (to > from)
                c.lm--;
            }
            if (to > otherTo) {
              c.lm++;
            } else if (to === otherTo) {
              // if we're both moving in the same direction, tie break
              if ((otherTo > otherFrom && to > from) ||
                  (otherTo < otherFrom && to < from)) {
                if (type === 'right') c.lm++;
              } else {
                if (to > from) c.lm++;
                else if (to === otherFrom) c.lm--;
              }
            }
          }
        }
      } else if (c.li !== void 0 && c.ld === undefined && commonOperand) {
        // li
        var from = otherC.p[common];
        var to = otherC.lm;
        p = c.p[common];
        if (p > from) c.p[common]--;
        if (p > to) c.p[common]++;
      } else {
        // ld, ld+li, si, sd, na, oi, od, oi+od, any li on an element beneath
        // the lm
        //
        // i.e. things care about where their item is after the move.
        var from = otherC.p[common];
        var to = otherC.lm;
        p = c.p[common];
        if (p === from) {
          c.p[common] = to;
        } else {
          if (p > from) c.p[common]--;
          if (p > to) c.p[common]++;
          else if (p === to && from > to) c.p[common]++;
        }
      }
    }
    else if (otherC.oi !== void 0 && otherC.od !== void 0) {
      if (c.p[common] === otherC.p[common]) {
        if (c.oi !== void 0 && commonOperand) {
          // we inserted where someone else replaced
          if (type === 'right') {
            // left wins
            return dest;
          } else {
            // we win, make our op replace what they inserted
            c.od = otherC.oi;
          }
        } else {
          // -> noop if the other component is deleting the same object (or any parent)
          return dest;
        }
      }
    } else if (otherC.oi !== void 0) {
      if (c.oi !== void 0 && c.p[common] === otherC.p[common]) {
        // left wins if we try to insert at the same place
        if (type === 'left') {
          json.append(dest,{p: c.p, od:otherC.oi});
        } else {
          return dest;
        }
      }
    } else if (otherC.od !== void 0) {
      if (c.p[common] == otherC.p[common]) {
        if (!commonOperand)
          return dest;
        if (c.oi !== void 0) {
          delete c.od;
        } else {
          return dest;
        }
      }
    }
  }

  json.append(dest,c);
  return dest;
};

exports._bootstrapTransform(json, json.transformComponent, json.checkValidOp, json.append);


module.exports = json;
// This is included after the JS for each type when we build for the web.

  var _types = window.ottypes = window.ottypes || {};
  var _t = module.exports;
  _types[_t.name] = _t;

  if (_t.uri) _types[_t.uri] = _t;
})();

},{}],12:[function(require,module,exports){
module.exports = function genid(len, prefix, keyspace) {
  if (len == null) {
    len = 32;
  }
  if (prefix == null) {
    prefix = "";
  }
  if (keyspace == null) {
    keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  }
  while (len-- > 0) {
    prefix += keyspace.charAt(Math.floor(Math.random() * keyspace.length));
  }
  return prefix;
};
},{}],13:[function(require,module,exports){
/**
 * @license
 * Lo-Dash 2.0.0 <http://lodash.com/>
 * Copyright 2012-2013 The Dojo Foundation <http://dojofoundation.org/>
 * Based on Underscore.js 1.5.2 <http://underscorejs.org/LICENSE>
 * Copyright 2009-2013 Jeremy Ashkenas, DocumentCloud and Investigative Reporters & Editors
 * Available under MIT license <http://lodash.com/license>
 */
var isFunction = require('lodash.isfunction'),
    isObject = require('lodash.isobject'),
    reNative = require('lodash._renative');

/** Used as a safe reference for `undefined` in pre ES5 environments */
var undefined;

/** Used for native method references */
var objectProto = Object.prototype;

/** Native method shortcuts */
var now = reNative.test(now = Date.now) && now || function() { return +new Date; };

/* Native method shortcuts for methods with the same name as other `lodash` methods */
var nativeMax = Math.max;

/**
 * Creates a function that will delay the execution of `func` until after
 * `wait` milliseconds have elapsed since the last time it was invoked.
 * Provide an options object to indicate that `func` should be invoked on
 * the leading and/or trailing edge of the `wait` timeout. Subsequent calls
 * to the debounced function will return the result of the last `func` call.
 *
 * Note: If `leading` and `trailing` options are `true` `func` will be called
 * on the trailing edge of the timeout only if the the debounced function is
 * invoked more than once during the `wait` timeout.
 *
 * @static
 * @memberOf _
 * @category Functions
 * @param {Function} func The function to debounce.
 * @param {number} wait The number of milliseconds to delay.
 * @param {Object} [options] The options object.
 * @param {boolean} [options.leading=false] Specify execution on the leading edge of the timeout.
 * @param {number} [options.maxWait] The maximum time `func` is allowed to be delayed before it's called.
 * @param {boolean} [options.trailing=true] Specify execution on the trailing edge of the timeout.
 * @returns {Function} Returns the new debounced function.
 * @example
 *
 * // avoid costly calculations while the window size is in flux
 * var lazyLayout = _.debounce(calculateLayout, 150);
 * jQuery(window).on('resize', lazyLayout);
 *
 * // execute `sendMail` when the click event is fired, debouncing subsequent calls
 * jQuery('#postbox').on('click', _.debounce(sendMail, 300, {
 *   'leading': true,
 *   'trailing': false
 * });
 *
 * // ensure `batchLog` is executed once after 1 second of debounced calls
 * var source = new EventSource('/stream');
 * source.addEventListener('message', _.debounce(batchLog, 250, {
 *   'maxWait': 1000
 * }, false);
 */
function debounce(func, wait, options) {
  var args,
      maxTimeoutId,
      result,
      stamp,
      thisArg,
      timeoutId,
      trailingCall,
      lastCalled = 0,
      maxWait = false,
      trailing = true;

  if (!isFunction(func)) {
    throw new TypeError;
  }
  wait = nativeMax(0, wait) || 0;
  if (options === true) {
    var leading = true;
    trailing = false;
  } else if (isObject(options)) {
    leading = options.leading;
    maxWait = 'maxWait' in options && (nativeMax(wait, options.maxWait) || 0);
    trailing = 'trailing' in options ? options.trailing : trailing;
  }
  var delayed = function() {
    var remaining = wait - (now() - stamp);
    if (remaining <= 0) {
      if (maxTimeoutId) {
        clearTimeout(maxTimeoutId);
      }
      var isCalled = trailingCall;
      maxTimeoutId = timeoutId = trailingCall = undefined;
      if (isCalled) {
        lastCalled = now();
        result = func.apply(thisArg, args);
      }
    } else {
      timeoutId = setTimeout(delayed, remaining);
    }
  };

  var maxDelayed = function() {
    if (timeoutId) {
      clearTimeout(timeoutId);
    }
    maxTimeoutId = timeoutId = trailingCall = undefined;
    if (trailing || (maxWait !== wait)) {
      lastCalled = now();
      result = func.apply(thisArg, args);
    }
  };

  return function() {
    args = arguments;
    stamp = now();
    thisArg = this;
    trailingCall = trailing && (timeoutId || !leading);

    if (maxWait === false) {
      var leadingCall = leading && !timeoutId;
    } else {
      if (!maxTimeoutId && !leading) {
        lastCalled = stamp;
      }
      var remaining = maxWait - (stamp - lastCalled);
      if (remaining <= 0) {
        if (maxTimeoutId) {
          maxTimeoutId = clearTimeout(maxTimeoutId);
        }
        lastCalled = stamp;
        result = func.apply(thisArg, args);
      }
      else if (!maxTimeoutId) {
        maxTimeoutId = setTimeout(maxDelayed, remaining);
      }
    }
    if (!timeoutId && wait !== maxWait) {
      timeoutId = setTimeout(delayed, wait);
    }
    if (leadingCall) {
      result = func.apply(thisArg, args);
    }
    return result;
  };
}

module.exports = debounce;

},{"lodash._renative":14,"lodash.isfunction":15,"lodash.isobject":16}],14:[function(require,module,exports){
/**
 * @license
 * Lo-Dash 2.0.0 <http://lodash.com/>
 * Copyright 2012-2013 The Dojo Foundation <http://dojofoundation.org/>
 * Based on Underscore.js 1.5.2 <http://underscorejs.org/LICENSE>
 * Copyright 2009-2013 Jeremy Ashkenas, DocumentCloud and Investigative Reporters & Editors
 * Available under MIT license <http://lodash.com/license>
 */

/** Used for native method references */
var objectProto = Object.prototype;

/** Used to detect if a method is native */
var reNative = RegExp('^' +
  String(objectProto.valueOf)
    .replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    .replace(/valueOf|for [^\]]+/g, '.+?') + '$'
);

module.exports = reNative;

},{}],15:[function(require,module,exports){
/**
 * @license
 * Lo-Dash 2.0.0 <http://lodash.com/>
 * Copyright 2012-2013 The Dojo Foundation <http://dojofoundation.org/>
 * Based on Underscore.js 1.5.2 <http://underscorejs.org/LICENSE>
 * Copyright 2009-2013 Jeremy Ashkenas, DocumentCloud and Investigative Reporters & Editors
 * Available under MIT license <http://lodash.com/license>
 */

/**
 * Checks if `value` is a function.
 *
 * @static
 * @memberOf _
 * @category Objects
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if the `value` is a function, else `false`.
 * @example
 *
 * _.isFunction(_);
 * // => true
 */
function isFunction(value) {
  return typeof value == 'function';
}

module.exports = isFunction;

},{}],16:[function(require,module,exports){
/**
 * @license
 * Lo-Dash 2.0.0 <http://lodash.com/>
 * Copyright 2012-2013 The Dojo Foundation <http://dojofoundation.org/>
 * Based on Underscore.js 1.5.2 <http://underscorejs.org/LICENSE>
 * Copyright 2009-2013 Jeremy Ashkenas, DocumentCloud and Investigative Reporters & Editors
 * Available under MIT license <http://lodash.com/license>
 */
var objectTypes = require('lodash._objecttypes');

/**
 * Checks if `value` is the language type of Object.
 * (e.g. arrays, functions, objects, regexes, `new Number(0)`, and `new String('')`)
 *
 * @static
 * @memberOf _
 * @category Objects
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if the `value` is an object, else `false`.
 * @example
 *
 * _.isObject({});
 * // => true
 *
 * _.isObject([1, 2, 3]);
 * // => true
 *
 * _.isObject(1);
 * // => false
 */
function isObject(value) {
  // check if the value is the ECMAScript language type of Object
  // http://es5.github.io/#x8
  // and avoid a V8 bug
  // http://code.google.com/p/v8/issues/detail?id=2291
  return !!(value && objectTypes[typeof value]);
}

module.exports = isObject;

},{"lodash._objecttypes":17}],17:[function(require,module,exports){
/**
 * @license
 * Lo-Dash 2.0.0 <http://lodash.com/>
 * Copyright 2012-2013 The Dojo Foundation <http://dojofoundation.org/>
 * Based on Underscore.js 1.5.2 <http://underscorejs.org/LICENSE>
 * Copyright 2009-2013 Jeremy Ashkenas, DocumentCloud and Investigative Reporters & Editors
 * Available under MIT license <http://lodash.com/license>
 */

/** Used to determine if values are of the language type Object */
var objectTypes = {
  'boolean': false,
  'function': true,
  'object': true,
  'number': false,
  'string': false,
  'undefined': false
};

module.exports = objectTypes;

},{}]},{},[1])
//@ sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiZ2VuZXJhdGVkLmpzIiwic291cmNlcyI6WyIvdmFyL2xpYi9zdGlja3NoaWZ0LzUyMjlmNzY2NTAwNDQ2YzAwMzAwMDA4MC9hcHAtcm9vdC9kYXRhLzYwNTY0My9hc3NldHMvanMvYXBwcy9lZGl0b3IuY29mZmVlIiwiL3Zhci9saWIvc3RpY2tzaGlmdC81MjI5Zjc2NjUwMDQ0NmMwMDMwMDAwODAvYXBwLXJvb3QvZGF0YS82MDU2NDMvYXNzZXRzL2pzL2RpcmVjdGl2ZXMvYm9yZGVyTGF5b3V0LmNvZmZlZSIsIi92YXIvbGliL3N0aWNrc2hpZnQvNTIyOWY3NjY1MDA0NDZjMDAzMDAwMDgwL2FwcC1yb290L2RhdGEvNjA1NjQzL2Fzc2V0cy9qcy9kaXJlY3RpdmVzL2NvZGVFZGl0b3IuY29mZmVlIiwiL3Zhci9saWIvc3RpY2tzaGlmdC81MjI5Zjc2NjUwMDQ0NmMwMDMwMDAwODAvYXBwLXJvb3QvZGF0YS82MDU2NDMvYXNzZXRzL2pzL2RpcmVjdGl2ZXMvcHJldmlld2VyLmNvZmZlZSIsIi92YXIvbGliL3N0aWNrc2hpZnQvNTIyOWY3NjY1MDA0NDZjMDAzMDAwMDgwL2FwcC1yb290L2RhdGEvNjA1NjQzL2Fzc2V0cy9qcy9zZXJ2aWNlcy9hbm5vdGF0aW9ucy5jb2ZmZWUiLCIvdmFyL2xpYi9zdGlja3NoaWZ0LzUyMjlmNzY2NTAwNDQ2YzAwMzAwMDA4MC9hcHAtcm9vdC9kYXRhLzYwNTY0My9hc3NldHMvanMvc2VydmljZXMvc2Vzc2lvbi5jb2ZmZWUiLCIvdmFyL2xpYi9zdGlja3NoaWZ0LzUyMjlmNzY2NTAwNDQ2YzAwMzAwMDA4MC9hcHAtcm9vdC9kYXRhLzYwNTY0My9hc3NldHMvanMvc2VydmljZXMvc2V0dGluZ3MuY29mZmVlIiwiL3Zhci9saWIvc3RpY2tzaGlmdC81MjI5Zjc2NjUwMDQ0NmMwMDMwMDAwODAvYXBwLXJvb3QvZGF0YS82MDU2NDMvYXNzZXRzL2pzL3NlcnZpY2VzL3R5cGVzLmNvZmZlZSIsIi92YXIvbGliL3N0aWNrc2hpZnQvNTIyOWY3NjY1MDA0NDZjMDAzMDAwMDgwL2FwcC1yb290L2RhdGEvNjA1NjQzL2Fzc2V0cy9qcy9zZXJ2aWNlcy91cmwuY29mZmVlIiwiL3Zhci9saWIvc3RpY2tzaGlmdC81MjI5Zjc2NjUwMDQ0NmMwMDMwMDAwODAvYXBwLXJvb3QvZGF0YS82MDU2NDMvYXNzZXRzL3ZlbmRvci9vcGVyYXRpdmUuanMiLCIvdmFyL2xpYi9zdGlja3NoaWZ0LzUyMjlmNzY2NTAwNDQ2YzAwMzAwMDA4MC9hcHAtcm9vdC9kYXRhLzYwNTY0My9hc3NldHMvdmVuZG9yL290dHlwZXMvd2ViY2xpZW50L2pzb24wLnVuY29tcHJlc3NlZC5qcyIsIi92YXIvbGliL3N0aWNrc2hpZnQvNTIyOWY3NjY1MDA0NDZjMDAzMDAwMDgwL2FwcC1yb290L2RhdGEvNjA1NjQzL25vZGVfbW9kdWxlcy9nZW5pZC9pbmRleC5qcyIsIi92YXIvbGliL3N0aWNrc2hpZnQvNTIyOWY3NjY1MDA0NDZjMDAzMDAwMDgwL2FwcC1yb290L2RhdGEvNjA1NjQzL25vZGVfbW9kdWxlcy9sb2Rhc2guZGVib3VuY2UvaW5kZXguanMiLCIvdmFyL2xpYi9zdGlja3NoaWZ0LzUyMjlmNzY2NTAwNDQ2YzAwMzAwMDA4MC9hcHAtcm9vdC9kYXRhLzYwNTY0My9ub2RlX21vZHVsZXMvbG9kYXNoLmRlYm91bmNlL25vZGVfbW9kdWxlcy9sb2Rhc2guX3JlbmF0aXZlL2luZGV4LmpzIiwiL3Zhci9saWIvc3RpY2tzaGlmdC81MjI5Zjc2NjUwMDQ0NmMwMDMwMDAwODAvYXBwLXJvb3QvZGF0YS82MDU2NDMvbm9kZV9tb2R1bGVzL2xvZGFzaC5kZWJvdW5jZS9ub2RlX21vZHVsZXMvbG9kYXNoLmlzZnVuY3Rpb24vaW5kZXguanMiLCIvdmFyL2xpYi9zdGlja3NoaWZ0LzUyMjlmNzY2NTAwNDQ2YzAwMzAwMDA4MC9hcHAtcm9vdC9kYXRhLzYwNTY0My9ub2RlX21vZHVsZXMvbG9kYXNoLmRlYm91bmNlL25vZGVfbW9kdWxlcy9sb2Rhc2guaXNvYmplY3QvaW5kZXguanMiLCIvdmFyL2xpYi9zdGlja3NoaWZ0LzUyMjlmNzY2NTAwNDQ2YzAwMzAwMDA4MC9hcHAtcm9vdC9kYXRhLzYwNTY0My9ub2RlX21vZHVsZXMvbG9kYXNoLmRlYm91bmNlL25vZGVfbW9kdWxlcy9sb2Rhc2guaXNvYmplY3Qvbm9kZV9tb2R1bGVzL2xvZGFzaC5fb2JqZWN0dHlwZXMvaW5kZXguanMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IjtBQUFBO0NBQUEsS0FBQTs7Q0FBQSxDQUFBLEtBQUEscUJBQUE7O0NBQUEsQ0FHQSxLQUFBLDRCQUFBOztDQUhBLENBSUEsS0FBQSwwQkFBQTs7Q0FKQSxDQUtBLEtBQUEseUJBQUE7O0NBTEEsQ0FRQSxDQUFTLEdBQVQsQ0FBZ0IsVUFBOEIsR0FBckMsS0FBcUMsSUFBQSxDQUFBOztDQVI5QyxDQWlCQSxJQUFNLEVBQU4sRUFBQTtFQUF1QyxDQUFXLEVBQXJCLENBQXFCLENBQUEsQ0FBdEIsQ0FBQTtDQUMxQixLQUFBLElBQUE7Q0FBQSxFQUFTLEdBQVQsQ0FBZ0IsR0FBUCxFQUFBO0NBQVQsRUFFaUIsR0FBakIsQ0FBQTtDQUZBLElBSUEsQ0FBQTtDQUFhLENBQU8sR0FBUCxHQUFBO1dBQ1g7Q0FBQSxDQUFVLE1BQVYsSUFBQTtDQUFBLENBQ1MsS0FBVCxLQUFBLG1kQURBO0VBa0JBLFVBbkJrQjtDQW1CbEIsQ0FBVSxNQUFWLElBQUE7Q0FBQSxDQUNTLEtBQVQsS0FBQSwrR0FEQTtFQVNBLFVBNUJrQjtDQTRCbEIsQ0FBVSxNQUFWLEdBQUEsQ0FBQTtDQUFBLENBQ1MsS0FBVCxLQUFBLFdBREE7WUE1QmtCO1VBQVA7Q0FKYixPQUlBO0NBSkEsRUF3Q2lCLEdBQWpCLENBQUEsRUFBaUI7Q0FDZixPQUFBLElBQUE7Q0FBQSxFQUFjLENBQVgsRUFBVyxFQUFkLEdBQWM7Q0FDWixLQUFNLEVBQU4sRUFBQTtDQUNPLEtBQUQsRUFBTixLQUFBLElBQUE7VUFIYTtDQXhDakIsTUF3Q2lCO0NBeENqQixFQTZDb0IsR0FBcEIsR0FBcUIsQ0FBckIsRUFBb0I7Q0FD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QUFVLEdBQVYsRUFBSDtDQUFrQyxHQUFBLGVBQU87WUFEM0M7Q0FBQSxRQUFBO0NBR0EsR0FBQSxDQUFZLFVBQUw7Q0FMVCxNQUNlO0NBdEJPO0NBQXhCLEVBQXdCO0NBSnhCOzs7OztBQ0FBO0NBQUEsS0FBQTs7Q0FBQSxDQUFBLENBQVMsR0FBVCxDQUFnQixjQUFQOztDQUFULENBRUEsQ0FBQSxFQUFBLENBQU0sRUFBTjtDQUZBOzs7OztBQ0FBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNucEJBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDejlCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDZEE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDdEpBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNwQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDM0JBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ3ZDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EiLCJzb3VyY2VzQ29udGVudCI6WyJyZXF1aXJlIFwiLi4vc2VydmljZXMvc2Vzc2lvbi5jb2ZmZWVcIlxyXG5cclxuXHJcbnJlcXVpcmUgXCIuLi9kaXJlY3RpdmVzL2JvcmRlckxheW91dC5jb2ZmZWVcIlxyXG5yZXF1aXJlIFwiLi4vZGlyZWN0aXZlcy9jb2RlRWRpdG9yLmNvZmZlZVwiXHJcbnJlcXVpcmUgXCIuLi9kaXJlY3RpdmVzL3ByZXZpZXdlci5jb2ZmZWVcIlxyXG5cclxuXHJcbm1vZHVsZSA9IGFuZ3VsYXIubW9kdWxlIFwicGx1bmtlci5hcHAuZWRpdG9yXCIsIFtcclxuICBcImZhLmJvcmRlckxheW91dFwiXHJcbiAgXHJcbiAgXCJwbHVua2VyLnNlcnZpY2Uuc2Vzc2lvblwiXHJcbiAgXHJcbiAgXCJwbHVua2VyLmRpcmVjdGl2ZS5jb2RlRWRpdG9yXCJcclxuICBcInBsdW5rZXIuZGlyZWN0aXZlLnByZXZpZXdlclwiXHJcbl1cclxuXHJcbm1vZHVsZS5jb250cm9sbGVyIFwiRWRpdG9yXCIsIFtcIiRzY29wZVwiLCBcInNlc3Npb25cIiwgKCRzY29wZSwgc2Vzc2lvbikgLT5cclxuICBjbGllbnQgPSBzZXNzaW9uLmNyZWF0ZUNsaWVudChcIk1haW5DdHJsXCIpXHJcbiAgXHJcbiAgJHNjb3BlLnNlc3Npb24gPSBjbGllbnRcclxuICBcclxuICBjbGllbnQucmVzZXQgZmlsZXM6IFtcclxuICAgIGZpbGVuYW1lOiBcImluZGV4Lmh0bWxcIlxyXG4gICAgY29udGVudDogXCJcIlwiXHJcbiAgICAgIDwhZG9jdHlwZSBodG1sPlxyXG4gICAgICA8aHRtbCBuZy1hcHA9XCJwbHVua2VyXCIgPlxyXG4gICAgICA8aGVhZD5cclxuICAgICAgICA8bWV0YSBjaGFyc2V0PVwidXRmLThcIj5cclxuICAgICAgICA8dGl0bGU+QW5ndWxhckpTIFBsdW5rZXI8L3RpdGxlPlxyXG4gICAgICAgIDxzY3JpcHQ+ZG9jdW1lbnQud3JpdGUoJzxiYXNlIGhyZWY9XCInICsgZG9jdW1lbnQubG9jYXRpb24gKyAnXCIgLz4nKTs8L3NjcmlwdD5cclxuICAgICAgICA8bGluayByZWw9XCJzdHlsZXNoZWV0XCIgaHJlZj1cInN0eWxlLmNzc1wiPlxyXG4gICAgICAgIDxzY3JpcHQgZGF0YS1yZXF1aXJlPVwiYW5ndWxhci5qc0AxLjEueFwiIHNyYz1cImh0dHA6Ly9jb2RlLmFuZ3VsYXJqcy5vcmcvMS4xLjQvYW5ndWxhci5qc1wiPjwvc2NyaXB0PlxyXG4gICAgICAgIDxzY3JpcHQgc3JjPVwiYXBwLmpzXCI+PC9zY3JpcHQ+XHJcbiAgICAgIDwvaGVhZD5cclxuICAgICAgPGJvZHkgbmctY29udHJvbGxlcj1cIk1haW5DdHJsXCI+XHJcbiAgICAgICAgPHA+SGVsbG8ge3tuYW1lfX0hPC9wPlxyXG4gICAgICA8L2JvZHk+XHJcbiAgICAgIDwvaHRtbD4gXHJcbiAgICBcIlwiXCJcclxuICAsXHJcbiAgICBmaWxlbmFtZTogXCJhcHAuanNcIlxyXG4gICAgY29udGVudDogXCJcIlwiXHJcbiAgICAgIHZhciBhcHAgPSBhbmd1bGFyLm1vZHVsZSgncGx1bmtlcicsIFtdKTtcclxuICAgICAgIFxyXG4gICAgICBhcHAuY29udHJvbGxlcignTWFpbkN0cmwnLCBmdW5jdGlvbigkc2NvcGUpIHtcclxuICAgICAgICAkc2NvcGUubmFtZSA9ICdXb3JsZCc7XHJcbiAgICAgIH0pO1xyXG4gICAgXCJcIlwiXHJcbiAgLFxyXG4gICAgZmlsZW5hbWU6IFwic3R5bGUuY3NzXCJcclxuICAgIGNvbnRlbnQ6IFwiXCJcIlxyXG4gICAgICBwIHtcclxuICAgICAgICBjb2xvcjogcmVkO1xyXG4gICAgICB9XHJcbiAgICBcIlwiXCJcclxuICBdXHJcbiAgXHJcbiAgJHNjb3BlLmFkZEZpbGUgPSAtPlxyXG4gICAgaWYgZmlsZW5hbWUgPSBwcm9tcHQoXCJGaWxlbmFtZT9cIilcclxuICAgICAgY2xpZW50LmZpbGVDcmVhdGUoZmlsZW5hbWUpXHJcbiAgICAgIGNsaWVudC5jdXJzb3JTZXRGaWxlKGZpbGVuYW1lKVxyXG4gIFxyXG4gICRzY29wZS5yZW5hbWVGaWxlID0gKG9sZF9maWxlbmFtZSkgLT5cclxuICAgIGlmIGNsaWVudC5oYXNGaWxlKG9sZF9maWxlbmFtZSkgYW5kIGZpbGVuYW1lID0gcHJvbXB0KFwiRmlsZW5hbWU/XCIsIG9sZF9maWxlbmFtZSlcclxuICAgICAgY2xpZW50LmZpbGVSZW5hbWUob2xkX2ZpbGVuYW1lLCBmaWxlbmFtZSkgICAgXHJcbiAgXHJcbiAgJHNjb3BlLnJlbW92ZUZpbGUgPSAoZmlsZW5hbWUpIC0+XHJcbiAgICBpZiBjbGllbnQuaGFzRmlsZShmaWxlbmFtZSkgYW5kIGNvbmZpcm0oXCJBcmUgeW91IHN1cmUgeW91IHdvdWxkIGxpa2UgdG8gZGVsZXRlICN7ZmlsZW5hbWV9P1wiKVxyXG4gICAgICBjbGllbnQuZmlsZVJlbW92ZShmaWxlbmFtZSlcclxuICBcclxuICAkc2NvcGUubW92ZVRvID0gKGZpbGVuYW1lKSAtPlxyXG4gICAgY2xpZW50LmN1cnNvclNldEZpbGUoZmlsZW5hbWUpXHJcbl0iLCJtb2R1bGUgPSBhbmd1bGFyLm1vZHVsZSBcImZhLmJvcmRlckxheW91dFwiLCBbXG5dXG5cbnRocm90dGxlID0gKGRlbGF5LCBmbikgLT5cbiAgdGhyb3R0bGVkID0gZmFsc2VcbiAgLT5cbiAgICByZXR1cm4gaWYgdGhyb3R0bGVkXG4gICAgXG4gICAgdGhyb3R0bGVkID0gdHJ1ZVxuICAgIHNldFRpbWVvdXQgLT5cbiAgICAgIHRocm90dGxlZCA9IGZhbHNlXG4gICAgLCBkZWxheVxuICAgIFxuICAgIGZuLmNhbGwoQCwgYXJndW1lbnRzLi4uKVxuXG5jbGFzcyBSZWdpb25cbiAgY29uc3RydWN0b3I6IChAd2lkdGggPSAwLCBAaGVpZ2h0ID0gMCkgLT5cbiAgICBAdG9wID0gMFxuICAgIEByaWdodCA9IDBcbiAgICBAYm90dG9tID0gMFxuICAgIEBsZWZ0ID0gMFxuICAgIFxuICBjYWxjdWxhdGVTaXplOiAob3JpZW50YXRpb24sIHRhcmdldCA9IDApIC0+XG4gICAgdG90YWwgPSBAZ2V0U2l6ZShvcmllbnRhdGlvbilcbiAgICBcbiAgICBpZiBhbmd1bGFyLmlzTnVtYmVyKHRhcmdldClcbiAgICAgIGlmIHRhcmdldCA+PSAxIHRoZW4gcmV0dXJuIE1hdGgucm91bmQodGFyZ2V0KVxuICAgICAgaWYgdGFyZ2V0ID49IDAgdGhlbiByZXR1cm4gTWF0aC5yb3VuZCh0YXJnZXQgKiB0b3RhbClcbiAgICAgIFxuICAgICAgcmV0dXJuIDBcbiAgICBcbiAgICAjIEtpbGwgd2hpdGVzcGFjZVxuICAgIHRhcmdldCA9IHRhcmdldC5yZXBsYWNlIC9cXHMrL21nLCBcIlwiXG4gICAgXG4gICAgIyBBbGxvdyBmb3IgY29tcGxleCBzaXplcywgZS5nLjogNTAlIC0gNHB4XG4gICAgaWYgKHRlcm1zID0gdGFyZ2V0LnNwbGl0KFwiLVwiLCAyKSkubGVuZ3RoIGlzIDIgdGhlbiByZXR1cm4gQGNhbGN1bGF0ZVNpemUob3JpZW50YXRpb24sIHRlcm1zWzBdKSAtIEBjYWxjdWxhdGVTaXplKG9yaWVudGF0aW9uLCB0ZXJtc1sxXSlcbiAgICBpZiAodGVybXMgPSB0YXJnZXQuc3BsaXQoXCIrXCIsIDIpKS5sZW5ndGggaXMgMiB0aGVuIHJldHVybiBAY2FsY3VsYXRlU2l6ZShvcmllbnRhdGlvbiwgdGVybXNbMF0pICsgQGNhbGN1bGF0ZVNpemUob3JpZW50YXRpb24sIHRlcm1zWzFdKVxuICAgICAgXG4gICAgaWYgbWF0Y2hlcyA9IHRhcmdldC5tYXRjaCAvXihcXGQrKXB4JC8gdGhlbiByZXR1cm4gcGFyc2VJbnQobWF0Y2hlc1sxXSwgMTApXG4gICAgaWYgbWF0Y2hlcyA9IHRhcmdldC5tYXRjaCAvXihcXGQrKD86XFwuXFxkKyk/KSUkLyB0aGVuIHJldHVybiBNYXRoLnJvdW5kKHRvdGFsICogcGFyc2VGbG9hdChtYXRjaGVzWzFdKSAvIDEwMClcbiAgICBcbiAgICB0aHJvdyBuZXcgRXJyb3IoXCJVbnN1cHBvcnRlZCBzaXplOiAje3RhcmdldH1cIilcbiAgXG4gIGNvbnN1bWU6IChhbmNob3IsIHNpemUgPSAwKSAtPlxuICAgIHN3aXRjaCBhbmNob3JcbiAgICAgIHdoZW4gXCJub3J0aFwiXG4gICAgICAgIHN0eWxlID0geyB0b3A6IFwiI3tAdG9wfXB4XCIsIHJpZ2h0OiBcIiN7QHJpZ2h0fXB4XCIsIGxlZnQ6IFwiI3tAbGVmdH1weFwiLCBoZWlnaHQ6IFwiI3tzaXplfXB4XCIgfVxuICAgICAgICBAdG9wICs9IHNpemVcbiAgICAgIHdoZW4gXCJlYXN0XCJcbiAgICAgICAgc3R5bGUgPSB7IHRvcDogXCIje0B0b3B9cHhcIiwgcmlnaHQ6IFwiI3tAcmlnaHR9cHhcIiwgYm90dG9tOiBcIiN7QGJvdHRvbX1weFwiLCB3aWR0aDogXCIje3NpemV9cHhcIiB9XG4gICAgICAgIEByaWdodCArPSBzaXplXG4gICAgICB3aGVuIFwic291dGhcIlxuICAgICAgICBzdHlsZSA9IHsgcmlnaHQ6IFwiI3tAcmlnaHR9cHhcIiwgYm90dG9tOiBcIiN7QGJvdHRvbX1weFwiLCBsZWZ0OiBcIiN7QGxlZnR9cHhcIiwgaGVpZ2h0OiBcIiN7c2l6ZX1weFwiIH1cbiAgICAgICAgQGJvdHRvbSArPSBzaXplXG4gICAgICB3aGVuIFwid2VzdFwiXG4gICAgICAgIHN0eWxlID0geyB0b3A6IFwiI3tAdG9wfXB4XCIsIGJvdHRvbTogXCIje0Bib3R0b219cHhcIiwgbGVmdDogXCIje0BsZWZ0fXB4XCIsIHdpZHRoOiBcIiN7c2l6ZX1weFwiIH1cbiAgICAgICAgQGxlZnQgKz0gc2l6ZVxuICAgICAgXG4gICAgc3R5bGVcbiAgICBcbiAgZ2V0SW5uZXJSZWdpb246IC0+XG4gICAgbmV3IFJlZ2lvbiBAd2lkdGggLSBAcmlnaHQgLSBAbGVmdCwgQGhlaWdodCAtIEB0b3AgLSBAYm90dG9tXG4gIFxuICBnZXRTaXplOiAob3JpZW50YXRpb24pIC0+XG4gICAgc3dpdGNoIG9yaWVudGF0aW9uXG4gICAgICB3aGVuIFwidmVydGljYWxcIiB0aGVuIEBoZWlnaHRcbiAgICAgIHdoZW4gXCJob3Jpem9udGFsXCIgdGhlbiBAd2lkdGhcbiAgXG4gIGdldEF2YWlsYWJsZVNpemU6IChvcmllbnRhdGlvbikgLT5cbiAgICBzd2l0Y2ggb3JpZW50YXRpb25cbiAgICAgIHdoZW4gXCJ2ZXJ0aWNhbFwiIHRoZW4gQGhlaWdodCAtIEB0b3AgLSBAYm90dG9tXG4gICAgICB3aGVuIFwiaG9yaXpvbnRhbFwiIHRoZW4gQHdpZHRoIC0gQHJpZ2h0IC0gQGxlZnRcbiAgXG4gIFxuXG5tb2R1bGUuZGlyZWN0aXZlIFwicGFuZVwiLCBbIC0+XG4gIHJlc3RyaWN0OiBcIkVcIlxuICByZXBsYWNlOiB0cnVlXG4gIHJlcXVpcmU6IFtcInBhbmVcIiwgXCJeYm9yZGVyTGF5b3V0XCJdXG4gIHRyYW5zY2x1ZGU6IHRydWVcbiAgc2NvcGU6IHRydWVcbiAgdGVtcGxhdGU6IFwiXCJcIlxuICAgIDxkaXYgY2xhc3M9XCJib3JkZXItbGF5b3V0LXBhbmVcIiBuZy1jbGFzcz1cIntjbG9zZWQ6ICFvcGVufVwiIG5nLXN0eWxlPVwic3R5bGVQYW5lXCI+XG4gICAgICA8ZGl2IGNsYXNzPVwiYm9yZGVyLWxheW91dC1wYW5lLW92ZXJsYXlcIiBuZy1zdHlsZT1cInN0eWxlQ29udGVudFwiPjwvZGl2PlxuICAgICAgPGRpdiBjbGFzcz1cImJvcmRlci1sYXlvdXQtcGFuZS1oYW5kbGVcIiBsYXlvdXQtaGFuZGxlIG5nLXN0eWxlPVwic3R5bGVIYW5kbGVcIj48L2Rpdj5cbiAgICAgIDxkaXYgY2xhc3M9XCJib3JkZXItbGF5b3V0LXBhbmUtc2Nyb2xsZXJcIiBuZy1zdHlsZT1cInN0eWxlQ29udGVudFwiIG5nLXRyYW5zY2x1ZGU+PC9kaXY+XG4gICAgPC9kaXY+XG4gIFwiXCJcIlxuICBjb250cm9sbGVyOiBbXCIkc2NvcGVcIiwgXCIkZWxlbWVudFwiLCBcIiRhdHRyc1wiLCAoJHNjb3BlLCAkZWxlbWVudCwgJGF0dHJzKSAtPlxuICAgIHBhbmUgPSBAXG4gICAgXG4gICAgJGF0dHJzLiRvYnNlcnZlIFwiYW5jaG9yXCIsIChhbmNob3IpIC0+XG4gICAgICBwYW5lLmFuY2hvciA9IGFuY2hvclxuICAgICAgcGFuZS5vcmllbnRhdGlvbiA9IHBhbmUuZ2V0T3JpZW50YXRpb24oYW5jaG9yKVxuICAgICAgXG4gICAgJGF0dHJzLiRvYnNlcnZlIFwib3BlblwiLCAob3BlbiA9IHRydWUsIHdhc09wZW4pIC0+ICRzY29wZS5vcGVuID0gISFvcGVuXG4gICAgXG4gICAgQGNoaWxkcmVuID0gW11cbiAgICBAb3BlblNpemUgPSAwXG4gICAgXG4gICAgQGF0dGFjaENoaWxkID0gKGNoaWxkKSAtPiBAY2hpbGRyZW4ucHVzaChjaGlsZClcbiAgICBcbiAgICBAZ2V0QW5jaG9yID0gLT4gJGF0dHJzLmFuY2hvclxuICAgIFxuICAgIEBnZXRPcmllbnRhdGlvbiA9IChhbmNob3IgPSAkYXR0cnMuYW5jaG9yKSAtPlxuICAgICAgc3dpdGNoIGFuY2hvclxuICAgICAgICB3aGVuIFwibm9ydGhcIiwgXCJzb3V0aFwiIHRoZW4gXCJ2ZXJ0aWNhbFwiXG4gICAgICAgIHdoZW4gXCJlYXN0XCIsIFwid2VzdFwiIHRoZW4gXCJob3Jpem9udGFsXCJcbiAgICBcbiAgICBAZ2V0Q29udGVudFN0eWxlID0gKGFuY2hvciwgaGFuZGxlU2l6ZSkgLT5cbiAgICAgIHN0eWxlID1cbiAgICAgICAgdG9wOiAwXG4gICAgICAgIHJpZ2h0OiAwXG4gICAgICAgIGJvdHRvbTogMFxuICAgICAgICBsZWZ0OiAwXG4gICAgICAgIFxuICAgICAgc3dpdGNoIGFuY2hvclxuICAgICAgICB3aGVuIFwibm9ydGhcIiB0aGVuIHN0eWxlLmJvdHRvbSA9IFwiI3toYW5kbGVTaXplfXB4XCJcbiAgICAgICAgd2hlbiBcImVhc3RcIiB0aGVuIHN0eWxlLmxlZnQgPSBcIiN7aGFuZGxlU2l6ZX1weFwiXG4gICAgICAgIHdoZW4gXCJzb3V0aFwiIHRoZW4gc3R5bGUudG9wID0gXCIje2hhbmRsZVNpemV9cHhcIlxuICAgICAgICB3aGVuIFwid2VzdFwiIHRoZW4gc3R5bGUucmlnaHQgPSBcIiN7aGFuZGxlU2l6ZX1weFwiXG4gICAgICBcbiAgICAgIHN0eWxlXG4gICAgICAgIFxuICAgIEBnZXRIYW5kbGVTdHlsZSA9IChhbmNob3IsIHJlZ2lvbiwgaGFuZGxlU2l6ZSkgLT5cbiAgICAgIFxuICAgICAgc3dpdGNoIGFuY2hvclxuICAgICAgICB3aGVuIFwibm9ydGhcIlxuICAgICAgICAgIGhlaWdodDogXCIje3JlZ2lvbi5jYWxjdWxhdGVTaXplKCd2ZXJ0aWNhbCcsIGhhbmRsZVNpemUpfXB4XCJcbiAgICAgICAgICByaWdodDogMFxuICAgICAgICAgIGxlZnQ6IDBcbiAgICAgICAgICBib3R0b206IDBcbiAgICAgICAgd2hlbiBcInNvdXRoXCIgXG4gICAgICAgICAgaGVpZ2h0OiBcIiN7cmVnaW9uLmNhbGN1bGF0ZVNpemUoJ3ZlcnRpY2FsJywgaGFuZGxlU2l6ZSl9cHhcIlxuICAgICAgICAgIHJpZ2h0OiAwXG4gICAgICAgICAgbGVmdDogMFxuICAgICAgICAgIHRvcDogMFxuICAgICAgICB3aGVuIFwiZWFzdFwiXG4gICAgICAgICAgd2lkdGg6IFwiI3tyZWdpb24uY2FsY3VsYXRlU2l6ZSgnaG9yaXpvbnRhbCcsIGhhbmRsZVNpemUpfXB4XCJcbiAgICAgICAgICB0b3A6IDBcbiAgICAgICAgICBib3R0b206IDBcbiAgICAgICAgICBsZWZ0OiAwXG4gICAgICAgIHdoZW4gXCJ3ZXN0XCIgXG4gICAgICAgICAgd2lkdGg6IFwiI3tyZWdpb24uY2FsY3VsYXRlU2l6ZSgnaG9yaXpvbnRhbCcsIGhhbmRsZVNpemUpfXB4XCJcbiAgICAgICAgICB0b3A6IDBcbiAgICAgICAgICBib3R0b206IDBcbiAgICAgICAgICByaWdodDogMFxuICAgIFxuICAgIEBvbkhhbmRsZURvd24gPSAtPlxuICAgICAgJGVsZW1lbnQuYWRkQ2xhc3MoXCJhY3RpdmVcIilcbiAgICAgIEBsYXlvdXQub25IYW5kbGVEb3duKClcbiAgICBAb25IYW5kbGVVcCA9IC0+XG4gICAgICAkZWxlbWVudC5yZW1vdmVDbGFzcyhcImFjdGl2ZVwiKVxuICAgICAgQGxheW91dC5vbkhhbmRsZVVwKClcbiAgICBcbiAgICBAdG9nZ2xlID0gKGNsb3NlZCA9ICEkc2NvcGUuY2xvc2VkKSAtPlxuICAgICAgJHNjb3BlLmNsb3NlZCA9ICEhY2xvc2VkXG4gICAgICBcbiAgICAgIGlmIGNsb3NlZCB0aGVuIEBvcGVuU2l6ZSA9IEBzaXplXG4gICAgICBlbHNlIEBzaXplID0gQG9wZW5TaXplXG4gICAgICBcbiAgICAgIEBsYXlvdXQucmVmbG93KClcbiAgICBcbiAgICBAcmVmbG93ID0gKHJlZ2lvbiwgdGFyZ2V0ID0gJGF0dHJzLnNpemUpIC0+XG4gICAgICBhbmNob3IgPSAkYXR0cnMuYW5jaG9yXG4gICAgICBcbiAgICAgIGlmIGFuY2hvciBpcyBcImNlbnRlclwiXG4gICAgICAgICRzY29wZS5zdHlsZVBhbmUgPVxuICAgICAgICAgIHRvcDogXCIje3JlZ2lvbi50b3B9cHhcIlxuICAgICAgICAgIHJpZ2h0OiBcIiN7cmVnaW9uLnJpZ2h0fXB4XCJcbiAgICAgICAgICBib3R0b206IFwiI3tyZWdpb24uYm90dG9tfXB4XCJcbiAgICAgICAgICBsZWZ0OiBcIiN7cmVnaW9uLmxlZnR9cHhcIlxuICAgICAgZWxzZVxuICAgICAgICBvcmllbnRhdGlvbiA9IEBnZXRPcmllbnRhdGlvbihhbmNob3IpXG4gICAgICAgIGhhbmRsZVNpemUgPSByZWdpb24uY2FsY3VsYXRlU2l6ZShvcmllbnRhdGlvbiwgJGF0dHJzLmhhbmRsZSB8fCAwKVxuXG4gICAgICAgIGlmICRzY29wZS5jbG9zZWRcbiAgICAgICAgICBzaXplID0gaGFuZGxlU2l6ZVxuICAgICAgICBlbHNlXG4gICAgICAgICAgc2l6ZSA9IHJlZ2lvbi5jYWxjdWxhdGVTaXplKG9yaWVudGF0aW9uLCB0YXJnZXQpXG4gICAgICAgICAgbWF4ID0gJGF0dHJzLm1heCB8fCBOdW1iZXIuTUFYX1ZBTFVFXG4gICAgICAgICAgbWluID0gJGF0dHJzLm1pbiB8fCAwXG4gICAgICAgICAgXG4gICAgICAgICAgXG4gICAgICAgICAgc2l6ZSA9IE1hdGgubWluKHNpemUsIHJlZ2lvbi5jYWxjdWxhdGVTaXplKG9yaWVudGF0aW9uLCBtYXgpKVxuICAgICAgICAgIHNpemUgPSBNYXRoLm1heChzaXplLCByZWdpb24uY2FsY3VsYXRlU2l6ZShvcmllbnRhdGlvbiwgbWluKSlcbiAgICAgICAgICBzaXplID0gTWF0aC5taW4oc2l6ZSwgcmVnaW9uLmdldEF2YWlsYWJsZVNpemUob3JpZW50YXRpb24pKVxuICAgICAgICAgIHNpemUgPSBNYXRoLm1heChzaXplLCBoYW5kbGVTaXplICsgMikgIyBXaHkgZG9lcyAxLjUgd29yayE/XG4gICAgICAgIFxuICAgICAgICBAc2l6ZSA9IHNpemVcbiAgICAgICAgXG4gICAgICAgICRzY29wZS5zdHlsZVBhbmUgPSByZWdpb24uY29uc3VtZShhbmNob3IsIHNpemUpXG4gICAgICAgICRzY29wZS5zdHlsZUNvbnRlbnQgPSBAZ2V0Q29udGVudFN0eWxlKGFuY2hvciwgaGFuZGxlU2l6ZSlcbiAgICAgICAgJHNjb3BlLnN0eWxlSGFuZGxlID0gQGdldEhhbmRsZVN0eWxlKGFuY2hvciwgcmVnaW9uLCBoYW5kbGVTaXplKVxuICAgICAgICBcbiAgICAgIGlmIEBjaGlsZHJlbi5sZW5ndGhcbiAgICAgICAgaW5uZXIgPSByZWdpb24uZ2V0SW5uZXJSZWdpb24oKVxuICAgICAgICBpbm5lciA9IGNoaWxkLnJlZmxvdyhpbm5lcikgZm9yIGNoaWxkIGluIEBjaGlsZHJlblxuICAgICAgXG4gICAgICByZXR1cm4gcmVnaW9uXG4gICAgXG4gICAgQHJlc2l6ZSA9ICh0YXJnZXQpIC0+XG4gICAgICAkYXR0cnMuJHNldCBcInNpemVcIiwgdGFyZ2V0IHx8IDBcbiAgICAgIFxuICAgICAgQGxheW91dC5yZWZsb3coKVxuICAgICAgXG4gIF1cbiAgbGluazogKCRzY29wZSwgJGVsLCAkYXR0cnMsIFtwYW5lLCBwYXJlbnRdKSAtPlxuICAgIHBhbmUubGF5b3V0ID0gcGFyZW50XG4gICAgcGFyZW50LmF0dGFjaENoaWxkKHBhbmUpXG4gICAgXG4gICAgJHNjb3BlLiR3YXRjaCBcImNvbnN0cmFpbmVkXCIsIChjb25zdHJhaW5lZCkgLT5cbiAgICAgIGlmIGNvbnN0cmFpbmVkIHRoZW4gJGVsLmFkZENsYXNzKFwiYm9yZGVyLWxheW91dC1jb25zdHJhaW5lZFwiKVxuICAgICAgZWxzZSAkZWwucmVtb3ZlQ2xhc3MoXCJib3JkZXItbGF5b3V0LWNvbnN0cmFpbmVkXCIpXG5dXG5cbm1vZHVsZS5kaXJlY3RpdmUgXCJsYXlvdXRIYW5kbGVcIiwgWyBcIiR3aW5kb3dcIiwgKCR3aW5kb3cpIC0+XG4gIHJlc3RyaWN0OiBcIkFcIlxuICByZXF1aXJlOiBbXCI/XnBhbmVcIiwgXCJeP2JvcmRlckxheW91dFwiXVxuICBsaW5rOiAoJHNjb3BlLCAkZWxlbWVudCwgJGF0dHJzLCBbcGFuZSwgbGF5b3V0XSkgLT5cbiAgICByZXR1cm4gdW5sZXNzIHBhbmVcbiAgICBcbiAgICBlbCA9ICRlbGVtZW50WzBdXG4gICAgXG4gICAgY2xpY2tSYWRpdXMgPSA1XG4gICAgY2xpY2tUaW1lID0gMzAwXG4gICAgXG4gICAgJHNjb3BlLiR3YXRjaCAoIC0+IHBhbmUuZ2V0T3JpZW50YXRpb24oKSApLCAob3JpZW50YXRpb24pIC0+XG4gICAgICBzd2l0Y2ggb3JpZW50YXRpb25cbiAgICAgICAgd2hlbiBcInZlcnRpY2FsXCIgdGhlbiAkZWxlbWVudC5hZGRDbGFzcyhcInZlcnRpY2FsXCIpXG4gICAgICAgIHdoZW4gXCJob3Jpem9udGFsXCIgdGhlbiAkZWxlbWVudC5hZGRDbGFzcyhcImhvcml6b250YWxcIilcbiAgICBcbiAgICBlbC5hZGRFdmVudExpc3RlbmVyIFwibW91c2Vkb3duXCIsIChlKSAtPlxuICAgICAgcmV0dXJuIHVubGVzcyBlLmJ1dHRvbiBpcyAwXG4gICAgICBcbiAgICAgIGFuY2hvciA9IHBhbmUuZ2V0QW5jaG9yKClcbiAgICAgIFxuICAgICAgaWYgYW5jaG9yIGluIFtcIm5vcnRoXCIsIFwic291dGhcIl0gdGhlbiBjb29yZCA9IFwic2NyZWVuWVwiXG4gICAgICBlbHNlIGlmIGFuY2hvciBpbiBbXCJ3ZXN0XCIsIFwiZWFzdFwiXSB0aGVuIGNvb3JkID0gXCJzY3JlZW5YXCJcblxuICAgICAgaWYgYW5jaG9yIGluIFtcIm5vcnRoXCIsIFwid2VzdFwiXSB0aGVuIHNjYWxlID0gMVxuICAgICAgZWxzZSBpZiBhbmNob3IgaW4gW1wic291dGhcIiwgXCJlYXN0XCJdIHRoZW4gc2NhbGUgPSAtMVxuICAgIFxuICAgICAgc3RhcnRQb3MgPSB7eDogZS5zY3JlZW5YLCB5OiBlLnNjcmVlbll9XG4gICAgICBzdGFydENvb3JkID0gZVtjb29yZF1cbiAgICAgIHN0YXJ0U2l6ZSA9IHBhbmUuc2l6ZVxuICAgICAgc3RhcnRUaW1lID0gRGF0ZS5ub3coKVxuICAgICAgXG4gICAgICBwYW5lLm9uSGFuZGxlRG93bigpXG4gICAgICBcbiAgICAgICMgTm90IHN1cmUgaWYgdGhpcyByZWFsbHkgYWRkcyB2YWx1ZSwgYnV0IGFkZGVkIGZvciBjb21wYXRpYmlsaXR5XG4gICAgICBlbC51bnNlbGVjdGFibGUgPSBcIm9uXCJcbiAgICAgIGVsLm9uc2VsZWN0c3RhcnQgPSAtPiBmYWxzZVxuICAgICAgZWwuc3R5bGUudXNlclNlbGVjdCA9IGVsLnN0eWxlLk1velVzZXJTZWxlY3QgPSBcIm5vbmVcIlxuICAgICAgXG4gICAgICAjIE51bGwgb3V0IHRoZSBldmVudCB0byByZS11c2UgZSBhbmQgcHJldmVudCBtZW1vcnkgbGVha3NcbiAgICAgICNlLnNldENhcHR1cmUoKVxuICAgICAgZS5wcmV2ZW50RGVmYXVsdCgpXG4gICAgICBlLmRlZmF1bHRQcmV2ZW50ZWQgPSB0cnVlXG4gICAgICBlID0gbnVsbFxuICAgICAgXG4gICAgICBoYW5kbGVDbGljayA9IChlKSAtPlxuICAgICAgICAkc2NvcGUuJGFwcGx5IC0+IHBhbmUudG9nZ2xlKClcbiAgICAgICAgICBcbiAgICAgIGhhbmRsZU1vdXNlTW92ZSA9IChlKSAtPlxuICAgICAgICAkZWxlbWVudC5hZGRDbGFzcyhcImJvcmRlci1sYXlvdXQtcGFuZS1tb3ZpbmdcIilcbiAgICAgIFxuICAgICAgICAjIEluc2lkZSBBbmd1bGFyJ3MgZGlnZXN0LCBkZXRlcm1pbmUgdGhlIGlkZWFsIHNpemUgb2YgdGhlIGVsZW1lbnRcbiAgICAgICAgIyBhY2NvcmRpbmcgdG8gbW92ZW1lbnRzIHRoZW4gZGV0ZXJtaW5lIGlmIHRob3NlIG1vdmVtZW50cyBoYXZlIGJlZW5cbiAgICAgICAgIyBjb25zdHJhaW5lZCBieSBib3VuZGFyaWVzLCBvdGhlciBwYW5lcyBvciBtaW4vbWF4IGNsYXVzZXNcbiAgICAgICAgJHNjb3BlLiRhcHBseSAtPiBwYW5lLnJlc2l6ZSB0YXJnZXRTaXplID0gc3RhcnRTaXplICsgc2NhbGUgKiAoZVtjb29yZF0gLSBzdGFydENvb3JkKVxuXG4gICAgICAgICMgTnVsbCBvdXQgdGhlIGV2ZW50IGluIGNhc2Ugb2YgbWVtb3J5IGxlYWtzXG4gICAgICAgICNlLnNldENhcHR1cmUoKVxuICAgICAgICBlLnByZXZlbnREZWZhdWx0KClcbiAgICAgICAgZS5kZWZhdWx0UHJldmVudGVkID0gdHJ1ZVxuICAgICAgICBlID0gbnVsbFxuICAgICAgICBcbiAgICAgIGhhbmRsZU1vdXNlVXAgPSAoZSkgLT5cbiAgICAgICAgZGlzcGxhY2VtZW50U3EgPSBNYXRoLnBvdyhlLnNjcmVlblggLSBzdGFydFBvcy54LCAyKSArIE1hdGgucG93KGUuc2NyZWVuWSAtIHN0YXJ0UG9zLnksIDIpXG4gICAgICAgIHRpbWVFbGFwc2VkID0gRGF0ZS5ub3coKSAtIHN0YXJ0VGltZVxuXG4gICAgICAgICR3aW5kb3cucmVtb3ZlRXZlbnRMaXN0ZW5lciBcIm1vdXNlbW92ZVwiLCBoYW5kbGVNb3VzZU1vdmVUaHJvdHRsZWQsIHRydWVcbiAgICAgICAgJHdpbmRvdy5yZW1vdmVFdmVudExpc3RlbmVyIFwibW91c2V1cFwiLCBoYW5kbGVNb3VzZVVwLCB0cnVlXG4gICAgICAgIFxuICAgICAgICBjbGVhbnVwID0gLT5cbiAgICAgICAgICAjIE51bGwgb3V0IHRoZSBldmVudCBpbiBjYXNlIG9mIG1lbW9yeSBsZWFrc1xuICAgICAgICAgICNlLnJlbGVhc2VDYXB0dXJlKClcbiAgICAgICAgICBlLnByZXZlbnREZWZhdWx0KClcbiAgICAgICAgICBlLmRlZmF1bHRQcmV2ZW50ZWQgPSB0cnVlXG4gICAgICAgICAgZSA9IG51bGxcblxuICAgICAgICAgIHBhbmUub25IYW5kbGVVcCgpXG4gICAgICAgIFxuIFxuICAgICAgICBpZiBkaXNwbGFjZW1lbnRTcSA8PSBNYXRoLnBvdyhjbGlja1JhZGl1cywgMikgYW5kIHRpbWVFbGFwc2VkIDw9IGNsaWNrVGltZVxuICAgICAgICAgIGhhbmRsZUNsaWNrKGUpXG4gICAgICAgICAgY2xlYW51cCgpXG4gICAgICAgICAgcmV0dXJuXG4gICAgICAgICAgXG4gICAgICAgICMgSW4gY2FzZSB0aGUgbW91c2UgaXMgcmVsZWFzZWQgYXQgdGhlIGVuZCBvZiBhIHRocm90dGxlIHBlcmlvZFxuICAgICAgICBoYW5kbGVNb3VzZU1vdmUoZSlcbiAgICAgICAgXG4gICAgICAgIGNsZWFudXAoKVxuXG4gICAgICBcbiAgICAgICMgUHJldmVudCB0aGUgcmVmbG93IGxvZ2ljIGZyb20gaGFwcGVuaW5nIHRvbyBvZnRlblxuICAgICAgaGFuZGxlTW91c2VNb3ZlVGhyb3R0bGVkID0gdGhyb3R0bGUoMTAsIGhhbmRsZU1vdXNlTW92ZSlcbiAgICBcbiAgICAgICR3aW5kb3cuYWRkRXZlbnRMaXN0ZW5lciBcIm1vdXNlbW92ZVwiLCBoYW5kbGVNb3VzZU1vdmVUaHJvdHRsZWQsIHRydWVcbiAgICAgICR3aW5kb3cuYWRkRXZlbnRMaXN0ZW5lciBcIm1vdXNldXBcIiwgaGFuZGxlTW91c2VVcCwgdHJ1ZVxuXG5dXG5cblxubW9kdWxlLmRpcmVjdGl2ZSBcImJvcmRlckxheW91dFwiLCBbIFwiJHdpbmRvd1wiLCBcIiR0aW1lb3V0XCIsICgkd2luZG93LCAkdGltZW91dCktPlxuICByZXN0cmljdDogXCJFXCJcbiAgcmVwbGFjZTogdHJ1ZVxuICByZXF1aXJlOiBbXCJib3JkZXJMYXlvdXRcIiwgXCJeP3BhbmVcIl1cbiAgdHJhbnNjbHVkZTogdHJ1ZVxuICB0ZW1wbGF0ZTogXCJcIlwiXG4gICAgPGRpdiBjbGFzcz1cImJvcmRlci1sYXlvdXRcIiBuZy10cmFuc2NsdWRlPlxuICAgIDwvZGl2PlxuICBcIlwiXCJcbiAgY29udHJvbGxlcjogW1wiJHNjb3BlXCIsIFwiJGVsZW1lbnRcIiwgXCIkYXR0cnNcIiwgKCRzY29wZSwgJGVsZW1lbnQsICRhdHRycykgLT5cbiAgICBsYXlvdXQgPSBAXG4gICAgXG4gICAgQGNoaWxkcmVuID0gW11cbiAgICBcbiAgICBAYXR0YWNoQ2hpbGQgPSAoY2hpbGQpIC0+XG4gICAgICBAY2hpbGRyZW4ucHVzaChjaGlsZClcbiAgICBcbiAgICBAb25IYW5kbGVEb3duID0gLT4gJGVsZW1lbnQuYWRkQ2xhc3MoXCJhY3RpdmVcIilcbiAgICBAb25IYW5kbGVVcCA9IC0+XG4gICAgICAkZWxlbWVudC5yZW1vdmVDbGFzcyhcImFjdGl2ZVwiKVxuICAgICAgJHNjb3BlLiRicm9hZGNhc3QgXCJib3JkZXItbGF5b3V0LXJlZmxvd1wiXG4gICAgXG4gICAgQHJlZmxvdyA9IChyZWdpb24pIC0+XG4gICAgICB3aWR0aCA9ICRlbGVtZW50WzBdLm9mZnNldFdpZHRoXG4gICAgICBoZWlnaHQgPSAkZWxlbWVudFswXS5vZmZzZXRIZWlnaHRcbiAgICAgIFxuICAgICAgcmVnaW9uIHx8PSBuZXcgUmVnaW9uKHdpZHRoLCBoZWlnaHQpXG4gICAgICBcbiAgICAgIHJlZ2lvbiA9IGNoaWxkLnJlZmxvdyhyZWdpb24pIGZvciBjaGlsZCBpbiBAY2hpbGRyZW5cbiAgICAgICAgXG4gIF1cbiAgbGluazogKCRzY29wZSwgJGVsLCAkYXR0cnMsIFtsYXlvdXQsIHBhcmVudF0pIC0+XG4gICAgcGFyZW50LmF0dGFjaENoaWxkKGxheW91dCkgaWYgcGFyZW50XG4gICAgXG4gICAgJHNjb3BlLiRvbiBcInJlZmxvd1wiLCAtPlxuICAgICAgbGF5b3V0LnJlZmxvdygpIHVubGVzcyBwYXJlbnRcbiAgICBcbiAgICAkd2luZG93LmFkZEV2ZW50TGlzdGVuZXIgXCJyZXNpemVcIiwgKGUpIC0+XG4gICAgICBlLnN0b3BQcm9wYWdhdGlvbigpXG4gICAgICAkc2NvcGUuJGFwcGx5IC0+ICRzY29wZS4kYnJvYWRjYXN0IFwiYm9yZGVyLWxheW91dC1yZWZsb3dcIlxuICAgIFxuICAgICR0aW1lb3V0IC0+IGxheW91dC5yZWZsb3coKSB1bmxlc3MgcGFyZW50XG5dIiwicmVxdWlyZSBcIi4uL3NlcnZpY2VzL3Nlc3Npb24uY29mZmVlXCJcbnJlcXVpcmUgXCIuLi9zZXJ2aWNlcy90eXBlcy5jb2ZmZWVcIlxucmVxdWlyZSBcIi4uL3NlcnZpY2VzL3NldHRpbmdzLmNvZmZlZVwiXG5yZXF1aXJlIFwiLi4vc2VydmljZXMvYW5ub3RhdGlvbnMuY29mZmVlXCJcblxubW9kdWxlID0gYW5ndWxhci5tb2R1bGUgXCJwbHVua2VyLmRpcmVjdGl2ZS5jb2RlRWRpdG9yXCIsIFtcbiAgXCJwbHVua2VyLnNlcnZpY2Uuc2Vzc2lvblwiXG4gIFwicGx1bmtlci5zZXJ2aWNlLnR5cGVzXCJcbiAgXCJwbHVua2VyLnNlcnZpY2Uuc2V0dGluZ3NcIlxuICBcInBsdW5rZXIuc2VydmljZS5hbm5vdGF0aW9uc1wiXG5dXG5cbm1vZHVsZS5kaXJlY3RpdmUgXCJjb2RlRWRpdG9yXCIsIFsgXCIkcm9vdFNjb3BlXCIsIFwiJHRpbWVvdXRcIiwgXCJzZXNzaW9uXCIsIFwidHlwZXNcIiwgXCJzZXR0aW5nc1wiLCBcImFubm90YXRpb25zXCIsICgkcm9vdFNjb3BlLCAkdGltZW91dCwgc2Vzc2lvbiwgdHlwZXMsIHNldHRpbmdzLCBhbm5vdGF0aW9ucykgLT5cbiAgQWNlRWRpdG9yID0gYWNlLnJlcXVpcmUoXCJhY2UvZWRpdG9yXCIpLkVkaXRvclxuICBSZW5kZXJlciA9IGFjZS5yZXF1aXJlKFwiYWNlL3ZpcnR1YWxfcmVuZGVyZXJcIikuVmlydHVhbFJlbmRlcmVyXG4gIEVkaXRTZXNzaW9uID0gYWNlLnJlcXVpcmUoXCJhY2UvZWRpdF9zZXNzaW9uXCIpLkVkaXRTZXNzaW9uXG4gIFVuZG9NYW5hZ2VyID0gYWNlLnJlcXVpcmUoXCJhY2UvdW5kb21hbmFnZXJcIikuVW5kb01hbmFnZXJcbiAgUmFuZ2UgPSBhY2UucmVxdWlyZShcImFjZS9yYW5nZVwiKS5SYW5nZVxuICBcbiAgY29uZmlnID0gYWNlLnJlcXVpcmUoXCJhY2UvY29uZmlnXCIpXG4gIFxuICByZXN0cmljdDogXCJFXCJcbiAgcmVwbGFjZTogdHJ1ZVxuICBzY29wZTpcbiAgICBhY3RpdmU6IFwiPVwiXG4gIHRlbXBsYXRlOiBcIlwiXCJcbiAgICA8ZGl2IGNsYXNzPVwiY29kZS1lZGl0b3JcIj5cbiAgICA8L2Rpdj5cbiAgXCJcIlwiXG4gIGxpbms6ICgkc2NvcGUsICRlbCwgYXR0cnMpIC0+XG4gICAgZWRpdG9yID0gbmV3IEFjZUVkaXRvcihuZXcgUmVuZGVyZXIoJGVsWzBdLCBcImFjZS90aGVtZS8je3NldHRpbmdzLmVkaXRvci50aGVtZX1cIikpXG4gICAgY2xpZW50ID0gc2Vzc2lvbi5jcmVhdGVDbGllbnQoXCJjb2RlLWVkaXRvclwiKVxuICAgIHNuaXBwZXRNYW5hZ2VyID0gbnVsbFxuICAgIGJ1ZmZlcnMgPSBbXVxuICAgIFxuICAgIGFjZS5jb25maWcubG9hZE1vZHVsZSBcImFjZS9leHQvbGFuZ3VhZ2VfdG9vbHNcIiwgLT5cbiAgICAgIGVkaXRvci5zZXRPcHRpb25zXG4gICAgICAgIGVuYWJsZUJhc2ljQXV0b2NvbXBsZXRpb246IHRydWVcbiAgICAgICAgZW5hYmxlU25pcHBldHM6IHRydWVcbiAgXG4gICAgICBzbmlwcGV0TWFuYWdlciA9IGFjZS5yZXF1aXJlKFwiYWNlL3NuaXBwZXRzXCIpLnNuaXBwZXRNYW5hZ2VyXG4gICAgICBcbiAgICAkc2NvcGUuJHdhdGNoICggLT4gc2V0dGluZ3MuZWRpdG9yLnRoZW1lICksICh0aGVtZSkgLT5cbiAgICAgIGVkaXRvci5zZXRUaGVtZShcImFjZS90aGVtZS8je3RoZW1lfVwiKSBpZiB0aGVtZVxuICAgIFxuXG4gICAgZ3Vlc3NNb2RlID0gKGZpbGVuYW1lKSAtPiBcImFjZS9tb2RlL1wiICsgdHlwZXMuZ2V0QnlGaWxlbmFtZShmaWxlbmFtZSkubmFtZVxuICAgIFxuICAgIGFjdGl2YXRlQnVmZmVyID0gKGluZGV4KSAtPlxuICAgICAgZWRpdG9yLnNldFNlc3Npb24oYnVmZmVyc1tpbmRleF0pXG4gICAgICBlZGl0b3IuZm9jdXMoKVxuICAgIFxuICAgIG1vdmVDdXJzb3IgPSAob2Zmc2V0KSAtPlxuICAgICAgZG9jID0gZWRpdG9yLnNlc3Npb24uZG9jXG4gICAgICBlZGl0b3IubW92ZUN1cnNvclRvUG9zaXRpb24oZG9jLmluZGV4VG9Qb3NpdGlvbihvZmZzZXQpKVxuICAgIFxuICAgIGFkZEFjZVNlc3Npb24gPSAoaW5kZXgsIGZpbGUpIC0+XG4gICAgICBhY2VTZXNzaW9uID0gbmV3IEVkaXRTZXNzaW9uKGZpbGUuY29udGVudCBvciBcIlwiKVxuICAgICAgYWNlU2Vzc2lvbi5zZXRVbmRvTWFuYWdlcihuZXcgVW5kb01hbmFnZXIoKSlcbiAgICAgIGFjZVNlc3Npb24uc2V0VXNlV29ya2VyKHRydWUpXG4gICAgICBhY2VTZXNzaW9uLnNldFRhYlNpemUoc2V0dGluZ3MuZWRpdG9yLnRhYl9zaXplKVxuICAgICAgYWNlU2Vzc2lvbi5zZXRVc2VXcmFwTW9kZSghIXNldHRpbmdzLmVkaXRvci53cmFwLmVuYWJsZWQpXG4gICAgICBhY2VTZXNzaW9uLnNldFdyYXBMaW1pdFJhbmdlKHNldHRpbmdzLmVkaXRvci53cmFwLnJhbmdlLm1pbiwgc2V0dGluZ3MuZWRpdG9yLndyYXAucmFuZ2UubWF4KVxuICAgICAgYWNlU2Vzc2lvbi5zZXRNb2RlKGd1ZXNzTW9kZShmaWxlLmZpbGVuYW1lKSlcblxuICAgICAgXG4gICAgICBkb2MgPSBhY2VTZXNzaW9uLmdldERvY3VtZW50KClcbiAgICAgICAgICBcbiAgICAgIGhhbmRsZUNoYW5nZUV2ZW50ID0gKGUpIC0+XG4gICAgICAgIHVubGVzcyAkcm9vdFNjb3BlLiQkcGhhc2UgdGhlbiAkc2NvcGUuJGFwcGx5IC0+XG4gICAgICAgICAgc3dpdGNoIGUuZGF0YS5hY3Rpb25cbiAgICAgICAgICAgIHdoZW4gXCJpbnNlcnRUZXh0XCIgdGhlbiBjbGllbnQudGV4dEluc2VydCBmaWxlLmZpbGVuYW1lLCBkb2MucG9zaXRpb25Ub0luZGV4KGUuZGF0YS5yYW5nZS5zdGFydCksIGUuZGF0YS50ZXh0XG4gICAgICAgICAgICB3aGVuIFwiaW5zZXJ0TGluZXNcIiB0aGVuIGNsaWVudC50ZXh0SW5zZXJ0IGZpbGUuZmlsZW5hbWUsIGRvYy5wb3NpdGlvblRvSW5kZXgoZS5kYXRhLnJhbmdlLnN0YXJ0KSwgZS5kYXRhLmxpbmVzLmpvaW4oZS5kYXRhLm5sKSArIGUuZGF0YS5ubFxuICAgICAgICAgICAgd2hlbiBcInJlbW92ZVRleHRcIiB0aGVuIGNsaWVudC50ZXh0UmVtb3ZlIGZpbGUuZmlsZW5hbWUsIGRvYy5wb3NpdGlvblRvSW5kZXgoZS5kYXRhLnJhbmdlLnN0YXJ0KSwgZS5kYXRhLnRleHRcbiAgICAgICAgICAgIHdoZW4gXCJyZW1vdmVMaW5lc1wiIHRoZW4gY2xpZW50LnRleHRSZW1vdmUgZmlsZS5maWxlbmFtZSwgZG9jLnBvc2l0aW9uVG9JbmRleChlLmRhdGEucmFuZ2Uuc3RhcnQpLCBlLmRhdGEubGluZXMuam9pbihlLmRhdGEubmwpICsgZS5kYXRhLm5sXG4gICAgICBcbiAgICAgIGhhbmRsZUNoYW5nZUFubm90YXRpb25FdmVudCA9IChlKSAtPlxuICAgICAgICB1bmxlc3MgJHJvb3RTY29wZS4kJHBoYXNlIHRoZW4gJHNjb3BlLiRhcHBseSAtPlxuICAgICAgICAgIGlmIChpZHggPSBjbGllbnQuZ2V0RmlsZUluZGV4KGZpbGUuZmlsZW5hbWUpKSA8IDBcbiAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcihcIkJ1ZmZlcnMgYW5kIHNlc3Npb24gYXJlIG91dCBvZiBzeW5jIGZvcjogI3tmaWxlLmZpbGVuYW1lfVwiKVxuICAgICAgICAgIFxuICAgICAgICAgIGFubm90YXRpb25zLnVwZGF0ZShmaWxlLmZpbGVuYW1lLCBhY2VTZXNzaW9uLmdldEFubm90YXRpb25zKCkpXG5cbiAgICAgIGJ1ZmZlcnNbaW5kZXhdID0gYWNlU2Vzc2lvblxuICAgICAgXG4gICAgICBhbm5vdGF0aW9ucy51cGRhdGUgZmlsZS5maWxlbmFtZSwgYWNlU2Vzc2lvbi5nZXRBbm5vdGF0aW9ucygpXG5cbiAgICAgIGFjZVNlc3Npb24ub24gXCJjaGFuZ2VcIiwgaGFuZGxlQ2hhbmdlRXZlbnRcbiAgICAgIGFjZVNlc3Npb24ub24gXCJjaGFuZ2VBbm5vdGF0aW9uXCIsIGhhbmRsZUNoYW5nZUFubm90YXRpb25FdmVudFxuXG4gICAgICBhY2VTZXNzaW9uLmRlc3Ryb3kgPSAtPlxuICAgICAgICBhY2VTZXNzaW9uLm9mZiBcImNoYW5nZVwiLCBoYW5kbGVDaGFuZ2VFdmVudFxuICAgICAgICBhY2VTZXNzaW9uLm9mZiBcImNoYW5nZUFubm90YXRpb25cIiwgaGFuZGxlQ2hhbmdlQW5ub3RhdGlvbkV2ZW50XG5cbiAgICByZW1vdmVBY2VTZXNzaW9uID0gKGluZGV4KSAtPlxuICAgICAgYnVmZmVyc1tpbmRleF0uZGVzdHJveSgpXG4gICAgICBidWZmZXJzLnNwbGljZSBpbmRleCwgMVxuICAgICAgXG4gICAgICBhbm5vdGF0aW9ucy5yZW1vdmUoZmlsZS5maWxlbmFtZSlcbiAgICAgIFxuICAgIHJlc2V0ID0gKHNuYXBzaG90KSAtPlxuICAgICAgcmVtb3ZlQWNlU2Vzc2lvbihpZHgpIGZvciBhY2VTZXNzaW9uLCBpZHggaW4gYnVmZmVyc1xuICAgICAgYWRkQWNlU2Vzc2lvbihpZHgsIGZpbGUpIGZvciBmaWxlLCBpZHggaW4gc25hcHNob3QuZmlsZXNcbiAgICBcbiAgICBjaGFuZ2VTZXNzaW9uTW9kZSA9IChpbmRleCwgZmlsZW5hbWUpIC0+XG4gICAgICBidWZmZXIuc2V0TW9kZShndWVzc01vZGUoZmlsZW5hbWUpKSBpZiBidWZmZXIgPSBidWZmZXJzW2luZGV4XVxuICAgICAgICBcbiAgICBjbGllbnQub24gXCJyZXNldFwiLCAoZSwgc25hcHNob3QpIC0+IHJlc2V0KGUuc25hcHNob3QpXG4gICAgXG4gICAgY2xpZW50Lm9uIFwiY3Vyc29yU2V0RmlsZVwiLCAoZSwgc25hcHNob3QpIC0+XG4gICAgICBhY3RpdmF0ZUJ1ZmZlcihlLmluZGV4KVxuICAgIFxuICAgIGNsaWVudC5vbiBcImN1cnNvclNldE9mZnNldFwiLCAoZSwgc25hcHNob3QpIC0+XG4gICAgICBtb3ZlQ3Vyc29yKGUub2Zmc2V0KVxuICAgICAgXG4gICAgY2xpZW50Lm9uIFwiZmlsZUNyZWF0ZVwiLCAoZSwgc25hcHNob3QpIC0+XG4gICAgICBhZGRBY2VTZXNzaW9uKGUuaW5kZXgsIHNuYXBzaG90LmZpbGVzW2UuaW5kZXhdKVxuICAgIFxuICAgIGNsaWVudC5vbiBcImZpbGVSZW1vdmVcIiwgKGUsIHNuYXBzaG90KSAtPlxuICAgICAgcmVtb3ZlQWNlU2Vzc2lvbihlLmluZGV4KVxuICAgICAgYW5ub3RhdGlvbnMucmVtb3ZlKGUuZmlsZW5hbWUpXG4gICAgXG4gICAgY2xpZW50Lm9uIFwiZmlsZVJlbmFtZVwiLCAoZSwgc25hcHNob3QpIC0+XG4gICAgICBjaGFuZ2VTZXNzaW9uTW9kZShlLmluZGV4LCBlLmZpbGVuYW1lKVxuICAgICAgY29uc29sZS5sb2cgXCJvbkZpbGVSZW5hbWVcIiwgZVxuICAgICAgYW5ub3RhdGlvbnMucmVuYW1lKGUuZmlsZW5hbWUsIGUub2xkX2ZpbGVuYW1lKVxuICAgIFxuICAgIGNsaWVudC5vbiBcInRleHRJbnNlcnRcIiwgKGUsIHNuYXBzaG90KSAtPlxuICAgICAgdGhyb3cgbmV3IEVycm9yKFwiUmVjZWl2ZWQgdGV4dEluc2VydCBldmVudCBmb3IgYSBmaWxlIG5vdCBiZWluZyB0cmFja2VkXCIpIHVubGVzcyBhY2VTZXNzaW9uID0gYnVmZmVyc1tlLmluZGV4XVxuICAgICAgYWNlU2Vzc2lvbi5kb2MuaW5zZXJ0IGFjZVNlc3Npb24uZG9jLmluZGV4VG9Qb3NpdGlvbihlLm9mZnNldCksIHRleHRcbiAgICAgIFxuICAgIGNsaWVudC5vbiBcInRleHRSZW1vdmVcIiwgKGUsIHNuYXBzaG90KSAtPlxuICAgICAgdGhyb3cgbmV3IEVycm9yKFwiUmVjZWl2ZWQgdGV4dEluc2VydCBldmVudCBmb3IgYSBmaWxlIG5vdCBiZWluZyB0cmFja2VkXCIpIHVubGVzcyBhY2VTZXNzaW9uID0gYnVmZmVyc1tlLmluZGV4XVxuICAgICAgYWNlU2Vzc2lvbi5kb2MucmVtb3ZlIFJhbmdlLmZyb21Qb2ludHMoYWNlU2Vzc2lvbi5kb2MuaW5kZXhUb1Bvc2l0aW9uKGUub2Zmc2V0KSwgYWNlU2Vzc2lvbi5kb2MuaW5kZXhUb1Bvc2l0aW9uKGUub2Zmc2V0ICsgZS50ZXh0Lmxlbmd0aCkpXG4gICAgXG4gICAgcmVzZXQoY2xpZW50LmdldFNuYXBzaG90KCkpXG4gICAgYWN0aXZhdGVCdWZmZXIoY2xpZW50LmdldEN1cnNvckZpbGVJbmRleCgpKVxuICAgIG1vdmVDdXJzb3IoY2xpZW50LmdldEN1cnNvclRleHRPZmZzZXQoKSlcbiAgICBcbiAgICAjIFJlc2l6ZSB0aGUgYWNlIGNvbXBvbmVudCB3aGVuZXZlciB3ZSBnZXQgYSByZWZsb3cgZXZlbnQgZnJvbSBib3JkZXItbGF5b3V0XG4gICAgJHNjb3BlLiRvbiBcImJvcmRlci1sYXlvdXQtcmVmbG93XCIsIC0+XG4gICAgICBlZGl0b3IucmVzaXplKClcblxuXSIsImdlbmlkID0gcmVxdWlyZShcImdlbmlkXCIpXG5kZWJvdW5jZSA9IHJlcXVpcmUoXCJsb2Rhc2guZGVib3VuY2VcIilcblxucmVxdWlyZSBcIi4uLy4uL3ZlbmRvci9vcGVyYXRpdmUuanNcIlxuXG5yZXF1aXJlIFwiLi4vc2VydmljZXMvc2Vzc2lvbi5jb2ZmZWVcIlxucmVxdWlyZSBcIi4uL3NlcnZpY2VzL3R5cGVzLmNvZmZlZVwiXG5yZXF1aXJlIFwiLi4vc2VydmljZXMvdXJsLmNvZmZlZVwiXG5yZXF1aXJlIFwiLi4vc2VydmljZXMvc2V0dGluZ3MuY29mZmVlXCJcbnJlcXVpcmUgXCIuLi9zZXJ2aWNlcy9hbm5vdGF0aW9ucy5jb2ZmZWVcIlxuXG5tb2R1bGUgPSBhbmd1bGFyLm1vZHVsZSBcInBsdW5rZXIuZGlyZWN0aXZlLnByZXZpZXdlclwiLCBbXG4gIFwicGx1bmtlci5zZXJ2aWNlLnNlc3Npb25cIlxuICBcInBsdW5rZXIuc2VydmljZS51cmxcIlxuICBcInBsdW5rZXIuc2VydmljZS5zZXR0aW5nc1wiXG4gIFwicGx1bmtlci5zZXJ2aWNlLmFubm90YXRpb25zXCJcbl1cblxubW9kdWxlLmRpcmVjdGl2ZSBcInByZXZpZXdlclwiLCBbIFwiJHRpbWVvdXRcIiwgXCJzZXNzaW9uXCIsIFwidXJsXCIsIFwic2V0dGluZ3NcIiwgXCJhbm5vdGF0aW9uc1wiLCAoJHRpbWVvdXQsIHNlc3Npb24sIHVybCwgc2V0dGluZ3MsIGFubm90YXRpb25zKSAtPlxuICByZXN0cmljdDogXCJFXCJcbiAgcmVwbGFjZTogdHJ1ZVxuICBzY29wZTpcbiAgICBzZXNzaW9uOiBcIj1cIlxuICB0ZW1wbGF0ZTogXCJcIlwiXG4gICAgPGRpdj5cbiAgICAgIDxkaXYgY2xhc3M9XCJwbHVua2VyLXByZXZpZXctY29udGFpbmVyXCIgbmctY2xhc3M9XCJ7bWVzc2FnZTogbWVzc2FnZX1cIj5cbiAgICAgICAgPGlmcmFtZSBuYW1lPVwicGx1bmtlclByZXZpZXdUYXJnZXRcIiBzcmM9XCJhYm91dDpibGFua1wiIHdpZHRoPVwiMTAwJVwiIGhlaWdodD1cIjQwMHB4XCIgZnJhbWVib3JkZXI9XCIwXCI+PC9pZnJhbWU+XG4gICAgICA8L2Rpdj5cbiAgICAgIDxkaXYgY2xhc3M9XCJwbHVua2VyLXByZXZpZXctbWVzc2FnZSBhbGVydCBhbGVydC1kYW5nZXJcIiBuZy1zaG93PVwibWVzc2FnZVwiPlxuICAgICAgICA8YnV0dG9uIHR5cGU9XCJidXR0b25cIiBjbGFzcz1cImNsb3NlXCIgbmctY2xpY2s9XCJtZXNzYWdlPScnXCIgYXJpYS1oaWRkZW49XCJ0cnVlXCI+JnRpbWVzOzwvYnV0dG9uPlxuICAgICAgICA8c3BhbiBuZy1iaW5kPVwibWVzc2FnZVwiPjwvc3Bhbj5cbiAgICAgIDwvZGl2PlxuICAgIDwvZGl2PlxuICBcIlwiXCJcbiAgbGluazogKCRzY29wZSwgJGVsLCBhdHRycykgLT5cbiAgICAkc2NvcGUucHJldmlld1VybCB8fD0gXCIje3VybC5ydW59LyN7Z2VuaWQoKX0vXCJcbiAgICBcbiAgICBjbGllbnQgPSBzZXNzaW9uLmNyZWF0ZUNsaWVudChcInByZXZpZXdlclwiKVxuICAgIFxuICAgIHJlZnJlc2ggPSAoc25hcHNob3QpIC0+ICRzY29wZS4kYXBwbHkgLT5cbiAgICAgIGNvbnNvbGUubG9nIFwiUmVmcmVzaFwiLCBzbmFwc2hvdCwgYW5ub3RhdGlvbnMuaGFzRXJyb3IoKSwgYW5ub3RhdGlvbnMuYW5ub3RhdGlvbnNcbiAgICAgIHJldHVybiBpZiAkc2NvcGUubW9kZSBpcyBcImRpc2FibGVkXCJcbiAgICAgIFxuICAgICAgaWYgZmlsZW5hbWUgPSBhbm5vdGF0aW9ucy5oYXNFcnJvcigpXG4gICAgICAgICRzY29wZS5tZXNzYWdlID0gXCJQcmV2aWV3IGhhcyBub3QgYmVlbiB1cGRhdGVkIGR1ZSB0byBzeW50YXggZXJyb3JzIGluICN7ZmlsZW5hbWV9XCJcbiAgICAgICAgcmV0dXJuXG4gICAgICBlbHNlXG4gICAgICAgICRzY29wZS5tZXNzYWdlID0gXCJcIlxuICAgICAgXG4gICAgICBmb3JtID0gZG9jdW1lbnQuY3JlYXRlRWxlbWVudChcImZvcm1cIilcbiAgICAgIGZvcm0uc3R5bGUuZGlzcGxheSA9IFwibm9uZVwiXG4gICAgICBmb3JtLnNldEF0dHJpYnV0ZSBcIm1ldGhvZFwiLCBcInBvc3RcIlxuICAgICAgZm9ybS5zZXRBdHRyaWJ1dGUgXCJhY3Rpb25cIiwgJHNjb3BlLnByZXZpZXdVcmxcbiAgICAgIGZvcm0uc2V0QXR0cmlidXRlIFwidGFyZ2V0XCIsIFwicGx1bmtlclByZXZpZXdUYXJnZXRcIlxuICAgICAgXG4gICAgICBmb3IgZmlsZSBpbiBzbmFwc2hvdC5maWxlc1xuICAgICAgICBmaWVsZCA9IGRvY3VtZW50LmNyZWF0ZUVsZW1lbnQoXCJpbnB1dFwiKVxuICAgICAgICBmaWVsZC5zZXRBdHRyaWJ1dGUgXCJ0eXBlXCIsIFwiaGlkZGVuXCJcbiAgICAgICAgZmllbGQuc2V0QXR0cmlidXRlIFwibmFtZVwiLCBcImZpbGVzWyN7ZmlsZS5maWxlbmFtZX1dW2NvbnRlbnRdXCJcbiAgICAgICAgZmllbGQuc2V0QXR0cmlidXRlIFwidmFsdWVcIiwgZmlsZS5jb250ZW50XG4gICAgICAgIFxuICAgICAgICBmb3JtLmFwcGVuZENoaWxkKGZpZWxkKVxuICAgICAgXG4gICAgICBkb2N1bWVudC5ib2R5LmFwcGVuZENoaWxkKGZvcm0pXG4gICAgICBcbiAgICAgIGZvcm0uc3VibWl0KClcbiAgICAgIFxuICAgICAgZG9jdW1lbnQuYm9keS5yZW1vdmVDaGlsZChmb3JtKVxuICAgIFxuICAgICRzY29wZS4kd2F0Y2ggKCAtPiBzZXR0aW5ncy5wcmV2aWV3ZXIuZGVsYXkpLCAoZGVsYXkpIC0+XG4gICAgICByZWZyZXNoID0gZGVib3VuY2UgcmVmcmVzaCwgZGVsYXlcbiAgICAgIFxuICAgIGNsaWVudC5vbiBcInJlc2V0XCIsIChlLCBzbmFwc2hvdCkgLT4gcmVmcmVzaChzbmFwc2hvdClcblxuICAgIGNsaWVudC5vbiBcImZpbGVDcmVhdGVcIiwgKGUsIHNuYXBzaG90KSAtPiByZWZyZXNoKHNuYXBzaG90KVxuICAgIGNsaWVudC5vbiBcImZpbGVSZW5hbWVcIiwgKGUsIHNuYXBzaG90KSAtPiByZWZyZXNoKHNuYXBzaG90KVxuICAgIGNsaWVudC5vbiBcImZpbGVSZW1vdmVcIiwgKGUsIHNuYXBzaG90KSAtPiByZWZyZXNoKHNuYXBzaG90KVxuXG4gICAgY2xpZW50Lm9uIFwidGV4dEluc2VydFwiLCAoZSwgc25hcHNob3QpIC0+IHJlZnJlc2goc25hcHNob3QpXG4gICAgY2xpZW50Lm9uIFwidGV4dFJlbW92ZVwiLCAoZSwgc25hcHNob3QpIC0+IHJlZnJlc2goc25hcHNob3QpXG4gICAgXG4gICAgJHRpbWVvdXQgLT4gcmVmcmVzaChjbGllbnQuZ2V0U25hcHNob3QoKSlcbl0iLCJtb2R1bGUgPSBhbmd1bGFyLm1vZHVsZSBcInBsdW5rZXIuc2VydmljZS5hbm5vdGF0aW9uc1wiLCBbXVxuXG5tb2R1bGUuZmFjdG9yeSBcImFubm90YXRpb25zXCIsIC0+XG4gIGFubm90YXRpb25zOiB7fVxuICBcbiAgdXBkYXRlOiAoZmlsZW5hbWUsIGFubm90YXRpb25zID0gW10pIC0+XG4gICAgYW5ndWxhci5jb3B5IGFubm90YXRpb25zLCAoQGFubm90YXRpb25zW2ZpbGVuYW1lXSB8fD0gW10pXG4gIFxuICByZW5hbWU6IChvbGRfZmlsZW5hbWUsIG5ld19maWxlbmFtZSkgLT5cbiAgICBAYW5ub3RhdGlvbnNbbmV3X2ZpbGVuYW1lXSA9IEBhbm5vdGF0aW9uc1tvbGRfZmlsZW5hbWVdIG9yIFtdXG4gICAgZGVsZXRlIEBhbm5vdGF0aW9uc1tvbGRfZmlsZW5hbWVdXG4gIFxuICByZW1vdmU6IChmaWxlbmFtZSkgLT5cbiAgICBkZWxldGUgQGFubm90YXRpb25zW2ZpbGVuYW1lXVxuICAgIFxuICBoYXNFcnJvcjogLT5cbiAgICBmb3IgZmlsZW5hbWUsIGFubm90YXRpb25zIG9mIEBhbm5vdGF0aW9uc1xuICAgICAgXG4gICAgICByZXR1cm4gZmlsZW5hbWUgZm9yIGFubm90YXRpb24gaW4gYW5ub3RhdGlvbnMgd2hlbiBhbm5vdGF0aW9uLnR5cGUgaXMgXCJlcnJvclwiXG4gICAgXG4gICAgcmV0dXJuIGZhbHNlIiwicmVxdWlyZSBcIi4uLy4uL3ZlbmRvci9vdHR5cGVzL3dlYmNsaWVudC9qc29uMC51bmNvbXByZXNzZWQuanNcIlxuXG5tb2R1bGUgPSBhbmd1bGFyLm1vZHVsZSBcInBsdW5rZXIuc2VydmljZS5zZXNzaW9uXCIsIFtcbl1cblxubW9kdWxlLnNlcnZpY2UgXCJzZXNzaW9uXCIsIGNsYXNzIFNlc3Npb25cbiAgIyBTZXNzaW9uQ2xpZW50IGlzIHRoZSBpbnRlcmZhY2UgdGhyb3VnaC13aGljaCBzdWJzY3JpYmVycyBjYW4gaXNzdWUgb3BlcmF0aW9ucyBvbiB0aGUgc2Vzc2lvblxuICBjbGFzcyBTZXNzaW9uQ2xpZW50XG4gICAgY29uc3RydWN0b3I6IChAbmFtZSwgQHNlc3Npb24pIC0+XG4gICAgICBAbGlzdGVuZXJzID0ge31cbiAgICAgIFxuICAgIG9uOiAoZXZlbnROYW1lLCBsaXN0ZW5lcikgLT4gKEBsaXN0ZW5lcnNbZXZlbnROYW1lXSB8fD0gW10pLnB1c2gobGlzdGVuZXIpXG4gICAgb2ZmOiAoZXZlbnROYW1lLCBsaXN0ZW5lcikgLT4gQGxpc3RlbmVycy5zcGxpY2UoaWR4LCAxKSB1bmxlc3MgMCA+IChpZHggPSBAbGlzdGVuZXJzLmluZGV4T2YobGlzdGVuZXIpKVxuICAgIFxuICAgIF9hcHBseU9wOiAob3ApIC0+IEBfYXBwbHlPcHMgW29wXVxuICAgIF9hcHBseU9wczogKG9wcykgLT4gQHNlc3Npb24uYXBwbHlPcHMgQG5hbWUsIG9wc1xuICAgIFxuICAgIF9oYW5kbGVPcDogKHNvdXJjZUNsaWVudE5hbWUsIG9wLCBzbmFwc2hvdCkgLT5cbiAgICAgIGlmIG9wLnAubGVuZ3RoIGlzIDBcbiAgICAgICAgQF9lbWl0IFwicmVzZXRcIixcbiAgICAgICAgICBzbmFwc2hvdDogb3Aub2lcbiAgICAgICAgICBvbGRfc25hcHNob3Q6IG9wLm9kXG4gICAgICBlbHNlXG4gICAgICAgIHN3aXRjaCBvcC5wWzBdXG4gICAgICAgICAgd2hlbiBcImN1cnNvclwiXG4gICAgICAgICAgICBpZiBvcC5wWzFdIGlzIFwiZmlsZUluZGV4XCIgdGhlbiBAX2VtaXQgXCJjdXJzb3JTZXRGaWxlXCIsXG4gICAgICAgICAgICAgIGZpbGVuYW1lOiBzbmFwc2hvdC5maWxlc1tvcC5vaV0uZmlsZW5hbWVcbiAgICAgICAgICAgICAgcHJldl9maWxlbmFtZTogc25hcHNob3QuZmlsZXNbb3Aub2RdLmZpbGVuYW1lXG4gICAgICAgICAgICAgIGluZGV4OiBvcC5vaVxuICAgICAgICAgICAgICBwcmV2X2luZGV4OiBvcC5vZFxuICAgICAgICAgICAgZWxzZSBpZiBvcC5wWzFdIGlzIFwidGV4dE9mZnNldFwiIHRoZW4gQF9lbWl0IFwiY3Vyc29yU2V0T2Zmc2V0XCIsXG4gICAgICAgICAgICAgIG9mZnNldDogb3Aub2lcbiAgICAgICAgICAgICAgcHJldl9vZmZzZXQ6IG9wLm9kXG4gICAgICAgICAgd2hlbiBcImRlc2NyaXB0aW9uXCJcbiAgICAgICAgICAgICMgQXNzdW1lIHNpL3NkIG9wcyBhdCBvZmZzZXQgPSAwXG4gICAgICAgICAgICByZXR1cm4gdW5sZXNzIG9wLnBbMV0gaXMgMFxuICAgICAgICAgICAgcmV0dXJuIHVubGVzcyBvcC5zaSBhbmQgb3Auc2RcbiAgICAgICAgICAgIFxuICAgICAgICAgICAgQF9lbWl0IFwic2V0RGVzY3JpcHRpb25cIixcbiAgICAgICAgICAgICAgZGVzY3JpcHRpb246IG9wLnNpXG4gICAgICAgICAgICAgIG9sZF9kZXNjcmlwdGlvbjogb3Auc2RcbiAgICAgICAgICB3aGVuIFwidGFnc1wiXG4gICAgICAgICAgICByZXR1cm4gdW5sZXNzIG9wLmxpIG9yIG9wLmxkXG4gICAgICAgICAgICByZXR1cm4gaWYgb3AucC5sZW5ndGggIT0gMlxuICAgICAgICAgICAgXG4gICAgICAgICAgICBpZiBvcC5saSB0aGVuIEBfZW1pdCBcInRhZ0FkZFwiLFxuICAgICAgICAgICAgICB0YWdOYW1lOiBvcC5saVxuICAgICAgICAgICAgICBpbmRleDogb3AucFsxXVxuICAgICAgICAgICAgZWxzZSBpZiBvcC5sZCB0aGVuIEBfZW1pdCBcInRhZ1JlbW92ZVwiLFxuICAgICAgICAgICAgICB0YWdOYW1lOiBvcC5sZFxuICAgICAgICAgICAgICBpbmRleDogb3AucFsyXVxuICAgICAgICAgIHdoZW4gXCJmaWxlc1wiXG4gICAgICAgICAgICAjIFRoaXMgaXMgYSBmaWxlIGNyZWF0aW9uL3JlbW92YWxcbiAgICAgICAgICAgIGlmIG9wLnAubGVuZ3RoIGlzIDJcbiAgICAgICAgICAgICAgaWYgb3AubGkgdGhlbiBAX2VtaXQgXCJmaWxlQ3JlYXRlXCIsXG4gICAgICAgICAgICAgICAgZmlsZW5hbWU6IG9wLmxpLmZpbGVuYW1lXG4gICAgICAgICAgICAgICAgaW5kZXg6IG9wLnBbMV1cbiAgICAgICAgICAgICAgICBjb250ZW50OiBvcC5saS5jb250ZW50XG4gICAgICAgICAgICAgIGVsc2UgaWYgb3AubGQgdGhlbiBAX2VtaXQgXCJmaWxlUmVtb3ZlXCIsXG4gICAgICAgICAgICAgICAgZmlsZW5hbWU6IG9wLmxkLmZpbGVuYW1lXG4gICAgICAgICAgICAgICAgaW5kZXg6IG9wLnBbMV1cbiAgICAgICAgICAgICAgICBjb250ZW50OiBvcC5sZC5jb250ZW50XG4gICAgICAgICAgICBcbiAgICAgICAgICAgIGVsc2UgaWYgb3AucFsyXSBpcyBcImZpbGVuYW1lXCJcbiAgICAgICAgICAgICAgQF9lbWl0IFwiZmlsZVJlbmFtZVwiLFxuICAgICAgICAgICAgICAgIGZpbGVuYW1lOiBvcC5vaVxuICAgICAgICAgICAgICAgIGluZGV4OiBvcC5wWzFdXG4gICAgICAgICAgICAgICAgb2xkX2ZpbGVuYW1lOiBvcC5vZFxuICAgICAgICAgICAgICAgIFxuICAgICAgICAgICAgZWxzZSBpZiBvcC5wWzJdIGlzIFwiY29udGVudFwiXG4gICAgICAgICAgICAgIGZpbGVuYW1lID0gc25hcHNob3QuZmlsZXNbb3AucFsxXV0uZmlsZW5hbWVcbiAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgIGlmIG9wLnNpIHRoZW4gQF9lbWl0IFwidGV4dEluc2VydFwiLFxuICAgICAgICAgICAgICAgIGZpbGVuYW1lOiBmaWxlbmFtZVxuICAgICAgICAgICAgICAgIGluZGV4OiBvcC5wWzFdXG4gICAgICAgICAgICAgICAgdGV4dDogb3Auc2lcbiAgICAgICAgICAgICAgICBvZmZzZXQ6IG9wLnBbM11cbiAgICAgICAgICAgICAgaWYgb3Auc2QgdGhlbiBAX2VtaXQgXCJ0ZXh0UmVtb3ZlXCIsXG4gICAgICAgICAgICAgICAgZmlsZW5hbWU6IGZpbGVuYW1lXG4gICAgICAgICAgICAgICAgaW5kZXg6IG9wLnBbMV1cbiAgICAgICAgICAgICAgICB0ZXh0OiBvcC5zZFxuICAgICAgICAgICAgICAgIG9mZnNldDogb3AucFszXVxuICAgICAgICAgICAgICAgIFxuICAgIF9lbWl0OiAoZXZlbnROYW1lLCBlKSAtPlxuICAgICAgc25hcHNob3QgPSBAZ2V0U25hcHNob3QoKVxuICAgICAgZS5ldmVudE5hbWUgPSBldmVudE5hbWVcbiAgICAgIFxuICAgICAgbGlzdGVuZXIoZSwgc25hcHNob3QpIGZvciBsaXN0ZW5lciBpbiBAbGlzdGVuZXJzW2V2ZW50TmFtZV0gaWYgQGxpc3RlbmVyc1tldmVudE5hbWVdXG4gICAgXG4gICAgZ2V0Q3Vyc29yRmlsZUluZGV4OiAtPiBAc2Vzc2lvbi5zbmFwc2hvdC5jdXJzb3IuZmlsZUluZGV4XG4gICAgXG4gICAgZ2V0Q3Vyc29yVGV4dE9mZnNldDogLT4gQHNlc3Npb24uc25hcHNob3QuY3Vyc29yLnRleHRPZmZzZXRcbiAgICBcbiAgICBnZXREZXNjcmlwdGlvbjogLT4gQHNlc3Npb24uc25hcHNob3QuZGVzY3JpcHRpb25cbiAgICBcbiAgICAjIFJldHVybiB2YWx1ZSBpcyBqdXN0IGxpa2UgaW5kZXhPZiAoPj0gMCBtZWFucyBmb3VuZCwgLTEgbWVhbnMgbm90IGZvdW5kKVxuICAgIGdldEZpbGVJbmRleDogKGZpbGVuYW1lKSAtPlxuICAgICAgcmV0dXJuIGlkeCBmb3IgZmlsZSwgaWR4IGluIEBzZXNzaW9uLnNuYXBzaG90LmZpbGVzIHdoZW4gZmlsZS5maWxlbmFtZSBpcyBmaWxlbmFtZVxuICAgICAgcmV0dXJuIC0xXG4gICAgXG4gICAgZ2V0RmlsZUJ5SW5kZXg6IChpZHgpIC0+XG4gICAgICBpZiBhbmd1bGFyLmlzU3RyaW5nKGlkeCkgdGhlbiBpZHggPSBAZ2V0RmlsZUluZGV4KGlkeClcbiAgICAgIFxuICAgICAgQHNlc3Npb24uc25hcHNob3QuZmlsZXNbaWR4XVxuICAgIFxuICAgIGdldEZpbGU6IChmaWxlbmFtZSkgLT5cbiAgICAgIHJldHVybiBmaWxlIGZvciBmaWxlIGluIEBzZXNzaW9uLnNuYXBzaG90LmZpbGVzIHdoZW4gZmlsZS5maWxlbmFtZSBpcyBmaWxlbmFtZVxuICAgIFxuICAgIGdldE51bUZpbGVzOiAtPiByZXR1cm4gQHNlc3Npb24uc25hcHNob3QuZmlsZXM/Lmxlbmd0aCBvciAwXG4gICAgXG4gICAgZ2V0TnVtVGFnczogLT4gcmV0dXJuIEBzZXNzaW9uLnNuYXBzaG90LnRhZ3M/Lmxlbmd0aCBvciAwXG4gICAgXG4gICAgZ2V0U25hcHNob3Q6IC0+IHJldHVybiBAc2Vzc2lvbi5zbmFwc2hvdFxuICAgIFxuICAgICMgUmV0dXJuIHZhbHVlIGlzIGp1c3QgbGlrZSBpbmRleE9mICg+PSAwIG1lYW5zIGZvdW5kLCAtMSBtZWFucyBub3QgZm91bmQpXG4gICAgZ2V0VGFnSW5kZXg6ICh0YWdOYW1lKSAtPlxuICAgICAgcmV0dXJuIGlkeCBmb3IgdGFnLCBpZHggaW4gQHNlc3Npb24uc25hcHNob3QudGFncyB3aGVuIHRhZyBpcyB0YWdOYW1lXG4gICAgICByZXR1cm4gLTFcbiAgICBcbiAgICBoYXNGaWxlOiAoZmlsZW5hbWUpIC0+IHJldHVybiBAZ2V0RmlsZUluZGV4KGZpbGVuYW1lKSA+PSAwXG5cbiAgICBoYXNGaWxlSW5kZXg6IChpZHgpIC0+IHJldHVybiBAZ2V0RmlsZUJ5SW5kZXgoaWR4KT9cbiAgICBcbiAgICBoYXNUYWc6ICh0YWdOYW1lKSAtPiByZXR1cm4gQGdldFRhZ0luZGV4KHRhZ05hbWUpID49IDBcbiAgICBcbiAgICBpc1ZhbGlkVGFnOiAodGFnTmFtZSkgLT4gcmV0dXJuIC9eWy1fYS16MC05XFwuXFxbXFxdXSskL2kudGVzdCh0YWdOYW1lKVxuICAgIFxuICAgIGlzVmFsaWRGaWxlOiAoZmlsZSkgLT4gcmV0dXJuIEBpc1ZhbGlkRmlsZW5hbWUoZmlsZS5maWxlbmFtZSkgJiYgYW5ndWxhci5pc1N0cmluZyhmaWxlLmNvbnRlbnQpXG4gICAgXG4gICAgaXNWYWxpZEZpbGVuYW1lOiAoZmlsZW5hbWUpIC0+IHJldHVybiAvXlstX2EtejAtOVxcLlxcW1xcXV0rJC9pLnRlc3QoZmlsZW5hbWUpXG4gICAgXG4gICAgXG4gICAgXG4gICAgcmVzZXQ6IChqc29uID0ge30pIC0+XG4gICAgICBqc29uLmRlc2NyaXB0aW9uIHx8PSBcIlwiXG4gICAgICBqc29uLnRhZ3MgfHw9IFtdXG4gICAgICBqc29uLmN1cnNvciB8fD0geyBmaWxlSW5kZXg6IDAsIHRleHRPZmZzZXQ6IDAgfVxuICAgICAgXG4gICAgICB0aHJvdyBuZXcgRXJyb3IoXCJSZXNldCBmYWlsZWQuIERlc2NyaXB0aW9uIG11c3QgYmUgYSBzdHJpbmcuXCIpIHVubGVzcyBhbmd1bGFyLmlzU3RyaW5nKGpzb24uZGVzY3JpcHRpb24pXG4gICAgICB0aHJvdyBuZXcgRXJyb3IoXCJSZXNldCBmYWlsZWQuIFRhZ3MgbXVzdCBiZSBhbiBhcnJheS5cIikgdW5sZXNzIGFuZ3VsYXIuaXNBcnJheShqc29uLnRhZ3MpXG4gICAgICB0aHJvdyBuZXcgRXJyb3IoXCJSZXNldCBmYWlsZWQuIEludmFsaWQgdGFnOiAje3RhZ05hbWV9LlwiKSBmb3IgdGFnTmFtZSBpbiBqc29uLnRhZ3Mgd2hlbiAhQGlzVmFsaWRUYWcodGFnTmFtZSlcbiAgICAgIHRocm93IG5ldyBFcnJvcihcIlJlc2V0IGZhaWxlZC4gRmlsZXMgbXVzdCBiZSBhbiBhcnJheS5cIikgdW5sZXNzIGFuZ3VsYXIuaXNBcnJheShqc29uLmZpbGVzKVxuICAgICAgdGhyb3cgbmV3IEVycm9yKFwiUmVzZXQgZmFpbGVkLiBJbnZhbGlkIGZpbGU6ICN7SlNPTi5zdHJpbmdpZnkoZmlsZSl9LlwiKSBmb3IgZmlsZSBpbiBqc29uLmZpbGVzIHdoZW4gIUBpc1ZhbGlkRmlsZShmaWxlKVxuICAgICAgdGhyb3cgbmV3IEVycm9yKFwiUmVzZXQgZmFpbGVkLiBUaGVyZSBtdXN0IGJlIGF0IGxlYXN0IG9uZSBmaWxlLlwiKSB1bmxlc3MganNvbi5maWxlcy5sZW5ndGhcbiAgICBcbiAgICAgIEBfYXBwbHlPcFxuICAgICAgICBwOiBbXVxuICAgICAgICBvZDogYW5ndWxhci5jb3B5KEBnZXRTbmFwc2hvdCgpKVxuICAgICAgICBvaToganNvblxuICAgIFxuICAgIGN1cnNvclNldEZpbGU6IChmaWxlbmFtZSkgLT5cbiAgICAgIHRocm93IG5ldyBFcnJvcihcIlVuYWJsZSBzZXQgdGhlIGFjdGl2ZSBmaWxlLiBGaWxlIGRvZXMgbm90IGV4aXN0OiAje2ZpbGVuYW1lfVwiKSB1bmxlc3MgQGhhc0ZpbGUoZmlsZW5hbWUpXG4gICAgICBcbiAgICAgIGlkeCA9IEBnZXRGaWxlSW5kZXgoZmlsZW5hbWUpXG4gICAgICBcbiAgICAgIEBfYXBwbHlPcFxuICAgICAgICBwOiBbXCJjdXJzb3JcIiwgXCJmaWxlSW5kZXhcIl1cbiAgICAgICAgb2Q6IEBnZXRDdXJzb3JGaWxlSW5kZXgoKVxuICAgICAgICBvaTogaWR4XG4gICAgXG4gICAgY3Vyc29yU2V0SW5kZXg6IChpZHgpIC0+XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoXCJVbmFibGUgc2V0IHRoZSBhY3RpdmUgZmlsZS4gRmlsZSBkb2VzIG5vdCBleGlzdDogI3tmaWxlbmFtZX1cIikgdW5sZXNzIEBoYXNGaWxlSW5kZXgoaWR4KVxuICAgICAgXG4gICAgICBAX2FwcGx5T3BcbiAgICAgICAgcDogW1wiY3Vyc29yXCIsIFwiZmlsZUluZGV4XCJdXG4gICAgICAgIG9kOiBAZ2V0Q3Vyc29yRmlsZUluZGV4KClcbiAgICAgICAgb2k6IGlkeFxuICAgIFxuICAgIGN1cnNvclNldE9mZnNldDogKG9mZnNldCkgLT5cbiAgICAgIEBfYXBwbHlPcFxuICAgICAgICBwOiBbXCJjdXJzb3JcIiwgXCJ0ZXh0T2Zmc2V0XCJdXG4gICAgICAgIG9kOiBAZ2V0Q3Vyc29yVGV4dE9mZnNldCgpXG4gICAgICAgIG9pOiBvZmZzZXRcbiAgICBcbiAgICBzZXREZXNjcmlwdGlvbjogKGRlc2NyaXB0aW9uID0gXCJcIikgLT5cbiAgICAgIEBfYXBwbHlPcFxuICAgICAgICBwOiBbXCJkZXNjcmlwdGlvblwiLCAwXVxuICAgICAgICBzZDogQGdldERlc2NyaXB0aW9uKClcbiAgICAgICAgc2k6IGRlc2NyaXB0aW9uXG4gICAgXG4gICAgXG4gICAgXG4gICAgZmlsZUNyZWF0ZTogKGZpbGVuYW1lLCBjb250ZW50ID0gXCJcIikgLT5cbiAgICAgIHRocm93IG5ldyBFcnJvcihcIlVuYWJsZSB0byBjcmVhdGUgZmlsZS4gSW52YWxpZCBmaWxlbmFtZTogI3tmaWxlbmFtZX1cIikgdW5sZXNzIEBpc1ZhbGlkRmlsZW5hbWUoZmlsZW5hbWUpXG4gICAgICB0aHJvdyBuZXcgRXJyb3IoXCJVbmFibGUgdG8gY3JlYXRlIGZpbGUuIEZpbGUgYWxyZWFkeSBleGlzdHM6ICN7ZmlsZW5hbWV9XCIpIGlmIEBoYXNGaWxlKGZpbGVuYW1lKVxuICAgICAgXG4gICAgICBpZHggPSBAZ2V0TnVtRmlsZXMoKVxuICAgICAgXG4gICAgICBAX2FwcGx5T3BcbiAgICAgICAgcDogW1wiZmlsZXNcIiwgaWR4XVxuICAgICAgICBsaToge2ZpbGVuYW1lLCBjb250ZW50fVxuICAgIFxuICAgIGZpbGVSZW5hbWU6IChmaWxlbmFtZSwgbmV3X2ZpbGVuYW1lKSAtPlxuICAgICAgdGhyb3cgbmV3IEVycm9yKFwiVW5hYmxlIHRvIGNyZWF0ZSBmaWxlLiBJbnZhbGlkIGZpbGVuYW1lOiAje25ld19maWxlbmFtZX1cIikgdW5sZXNzIEBpc1ZhbGlkRmlsZW5hbWUobmV3X2ZpbGVuYW1lKVxuICAgICAgdGhyb3cgbmV3IEVycm9yKFwiVW5hYmxlIHRvIHJlbmFtZSBmaWxlLiBGaWxlIGRvZXMgbm90IGV4aXN0OiAje2ZpbGVuYW1lfVwiKSB1bmxlc3MgQGhhc0ZpbGUoZmlsZW5hbWUpXG4gICAgICB0aHJvdyBuZXcgRXJyb3IoXCJVbmFibGUgdG8gcmVuYW1lIGZpbGUuIEEgZmlsZSBhbHJlYWR5IGV4aXN0cyBuYW1lZDogI3tuZXdfZmlsZW5hbWV9XCIpIGlmIEBoYXNGaWxlKG5ld19maWxlbmFtZSlcblxuICAgICAgaWR4ID0gQGdldEZpbGVJbmRleChmaWxlbmFtZSlcbiAgICAgIFxuICAgICAgQF9hcHBseU9wXG4gICAgICAgIHA6IFtcImZpbGVzXCIsIGlkeCwgXCJmaWxlbmFtZVwiXVxuICAgICAgICBvZDogZmlsZW5hbWVcbiAgICAgICAgb2k6IG5ld19maWxlbmFtZVxuXG4gICAgZmlsZVJlbW92ZTogKGZpbGVuYW1lKSAtPlxuICAgICAgdGhyb3cgbmV3IEVycm9yKFwiVW5hYmxlIHRvIHJlbW92ZSBmaWxlLiBGaWxlIGRvZXMgbm90IGV4aXN0OiAje2ZpbGVuYW1lfVwiKSB1bmxlc3MgQGhhc0ZpbGUoZmlsZW5hbWUpXG4gICAgICB0aHJvdyBuZXcgRXJyb3IoXCJVbmFibGUgdG8gcmVtb3ZlIGZpbGUuIFlvdSBjYW4gbm90IHJlbW92ZSBhbGwgZmlsZXMuXCIpIGlmIEBnZXROdW1GaWxlcygpIDw9IDFcblxuICAgICAgaWR4ID0gQGdldEZpbGVJbmRleChmaWxlbmFtZSlcbiAgICAgIFxuICAgICAgQGN1cnNvclNldEluZGV4KDApXG4gICAgXG4gICAgICBAX2FwcGx5T3BcbiAgICAgICAgcDogW1wiZmlsZXNcIiwgaWR4XVxuICAgICAgICBsZDogQGdldEZpbGUoZmlsZW5hbWUpXG4gICAgICAgIFxuICAgIFxuICAgIFxuICAgIHRleHRJbnNlcnQ6IChmaWxlbmFtZSwgb2Zmc2V0LCB0ZXh0KSAtPlxuICAgICAgdGhyb3cgbmV3IEVycm9yKFwiVW5hYmxlIHRvIGluc2VydCB0ZXh0LiBGaWxlIGRvZXMgbm90IGV4aXN0OiAje2ZpbGVuYW1lfVwiKSB1bmxlc3MgQGhhc0ZpbGUoZmlsZW5hbWUpXG4gICAgICBcbiAgICAgIGlkeCA9IEBnZXRGaWxlSW5kZXgoZmlsZW5hbWUpXG5cbiAgICAgIEBfYXBwbHlPcFxuICAgICAgICBwOiBbXCJmaWxlc1wiLCBpZHgsIFwiY29udGVudFwiLCBvZmZzZXRdXG4gICAgICAgIHNpOiB0ZXh0XG5cbiAgICB0ZXh0UmVtb3ZlOiAoZmlsZW5hbWUsIG9mZnNldCwgdGV4dCkgLT5cbiAgICAgIHRocm93IG5ldyBFcnJvcihcIlVuYWJsZSB0byByZW1vdmUgdGV4dC4gRmlsZSBkb2VzIG5vdCBleGlzdDogI3tmaWxlbmFtZX1cIikgdW5sZXNzIEBoYXNGaWxlKGZpbGVuYW1lKVxuICAgICAgXG4gICAgICBpZHggPSBAZ2V0RmlsZUluZGV4KGZpbGVuYW1lKVxuXG4gICAgICBAX2FwcGx5T3BcbiAgICAgICAgcDogW1wiZmlsZXNcIiwgaWR4LCBcImNvbnRlbnRcIiwgb2Zmc2V0XVxuICAgICAgICBzZDogdGV4dFxuICAgIFxuICAgIFxuICAgIFxuICAgIHRhZ0FkZDogKHRhZ05hbWUpIC0+XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoXCJVbmFibGUgdG8gYWRkIHRhZy4gSW52YWxpZCB0YWc6ICN7dGFnTmFtZX1cIikgdW5sZXNzIEBpc1ZhbGlkVGFnKHRhZ05hbWUpXG4gICAgICB0aHJvdyBuZXcgRXJyb3IoXCJVbmFibGUgdG8gYWRkIHRhZy4gVGFnIGFscmVhZHkgZXhpc3RzOiAje3RhZ05hbWV9XCIpIGlmIEBoYXNUYWcodGFnTmFtZSlcbiAgICAgIFxuICAgICAgaWR4ID0gQGdldE51bVRhZ3MoKVxuICAgICAgXG4gICAgICBAX2FwcGx5T3BcbiAgICAgICAgcDogW1widGFnc1wiLCBpZHhdXG4gICAgICAgIGxpOiB0YWdOYW1lXG5cbiAgICB0YWdSZW1vdmU6ICh0YWdOYW1lKSAtPlxuICAgICAgdGhyb3cgbmV3IEVycm9yKFwiVW5hYmxlIHRvIHJlbW92ZSB0YWcuIFRhZyBub3QgZm91bmQ6ICN7dGFnTmFtZX1cIikgdW5sZXNzIEBoYXNUYWcodGFnTmFtZSlcbiAgICAgIFxuICAgICAgaWR4ID0gQGdldFRhZ0luZGV4KHRhZ05hbWUpXG4gICAgICBcbiAgICAgIEBfYXBwbHlPcFxuICAgICAgICBwOiBbXCJ0YWdzXCIsIGlkeF1cbiAgICAgICAgbGQ6IHRhZ05hbWVcbiAgXG4gIFxuICBjb25zdHJ1Y3RvcjogLT5cbiAgICBAJGNsaWVudHMgPSB7fVxuICAgIFxuICAgIEBzbmFwc2hvdCA9IHt9XG4gICAgQGlmYWNlID0gQGNyZWF0ZUNsaWVudChcInNlc3Npb25cIilcbiAgICBcbiAgICBAaWZhY2UucmVzZXRcbiAgICAgIGZpbGVzOiBbXG4gICAgICAgIGZpbGVuYW1lOiBcImluZGV4Lmh0bWxcIlxuICAgICAgICBjb250ZW50OiBcIlwiXG4gICAgICBdXG4gIFxuICBjcmVhdGVDbGllbnQ6IChjbGllbnROYW1lKSAtPlxuICAgIHRocm93IG5ldyBFcnJvcihcIlVuYWJsZSB0byBjcmVhdGUgY2xpZW50LiBDbGllbnQgYWxyZWFkeSBjcmVhdGVkOiAje2NsaWVudE5hbWV9LlwiKSBpZiBAJGNsaWVudHNbY2xpZW50TmFtZV1cbiAgICBcbiAgICBzZXNzaW9uID0gQFxuICAgIFxuICAgIEAkY2xpZW50c1tjbGllbnROYW1lXSA9IG5ldyBTZXNzaW9uQ2xpZW50KGNsaWVudE5hbWUsIHNlc3Npb24pXG4gIFxuICBhcHBseU9wczogKHNvdXJjZUNsaWVudE5hbWUsIG9wcykgLT5cbiAgICBwb3N0U25hcHNob3QgPSBvdHR5cGVzLmpzb24wLmFwcGx5IEBzbmFwc2hvdCwgb3BzXG4gICAgXG4gICAgY29uc29sZS5sb2cgXCJbT1RdIG9wXCIsIG9wIGZvciBvcCBpbiBvcHNcbiAgICBjb25zb2xlLmxvZyBcIltPVF0gc25hcHNob3RcIiwgYW5ndWxhci5jb3B5KEBzbmFwc2hvdClcbiAgICBcbiAgICBhbmd1bGFyLmNvcHkgcG9zdFNuYXBzaG90LCBAc25hcHNob3QgdW5sZXNzIEBzbmFwc2hvdCA9PSBwb3N0U25hcHNob3RcbiAgICBcbiAgICBmb3IgY2xpZW50TmFtZSwgY2xpZW50IG9mIEAkY2xpZW50cyB3aGVuIGNsaWVudE5hbWUgIT0gc291cmNlQ2xpZW50TmFtZVxuICAgICAgY2xpZW50Ll9oYW5kbGVPcChzb3VyY2VDbGllbnROYW1lLCBvcCwgQHNuYXBzaG90KSBmb3Igb3AgaW4gb3BzXG4gICAgICBcbiIsIm1vZHVsZSA9IGFuZ3VsYXIubW9kdWxlIFwicGx1bmtlci5zZXJ2aWNlLnNldHRpbmdzXCIsIFtdXHJcblxyXG5tb2R1bGUuc2VydmljZSBcInNldHRpbmdzXCIsIFsgKCkgLT5cclxuICBcclxuICBzZXR0aW5ncyA9XHJcbiAgICBwcmV2aWV3ZXI6XHJcbiAgICAgIGRlbGF5OiAxMDAwXHJcbiAgICAgIGF1dG9fcmVmcmVzaDogdHJ1ZVxyXG4gICAgZWRpdG9yOlxyXG4gICAgICB0YWJfc2l6ZTogMlxyXG4gICAgICBzb2Z0X3RhYnM6IHRydWVcclxuICAgICAgdGhlbWU6IFwidGV4dG1hdGVcIlxyXG4gICAgICB3cmFwOlxyXG4gICAgICAgIHJhbmdlOlxyXG4gICAgICAgICAgbWluOiAwXHJcbiAgICAgICAgICBtYXg6IDgwXHJcbiAgICAgICAgZW5hYmxlZDogZmFsc2VcclxuICAgICAgICBcclxuICBcclxuICBcclxuICBpZiBsb2NhbFN0b3JhZ2U/XHJcbiAgICBpZiBzYXZlZCA9IGxvY2FsU3RvcmFnZS5nZXRJdGVtKFwicGxua3Jfc2V0dGluZ3NcIilcclxuICAgICAgdHJ5XHJcbiAgICAgICAgc2F2ZWQgPSBKU09OLnBhcnNlKHNhdmVkKVxyXG4gICAgICBjYXRjaCBlXHJcbiAgICAgICAgc2F2ZWQgPSB7fVxyXG4gICAgICBcclxuICAgIHNldEludGVydmFsIC0+XHJcbiAgICAgIGxvY2FsU3RvcmFnZS5zZXRJdGVtIFwicGxua3Jfc2V0dGluZ3NcIiwgSlNPTi5zdHJpbmdpZnkoc2V0dGluZ3MpXHJcbiAgICAsIDIwMDBcclxuICBcclxuICBhbmd1bGFyLmV4dGVuZCBzZXR0aW5ncywgc2F2ZWRcclxuICBcclxuXSIsIm1vZHVsZSA9IGFuZ3VsYXIubW9kdWxlIFwicGx1bmtlci5zZXJ2aWNlLnR5cGVzXCIsIFtcbl1cblxuXG5tb2R1bGUuZmFjdG9yeSBcInR5cGVzXCIsIC0+XG4gIHR5cGVzID1cbiAgICBodG1sOlxuICAgICAgcmVnZXg6IC9cXC5odG1sJC9pXG4gICAgICBtaW1lOiBcInRleHQvaHRtbFwiXG4gICAgamF2YXNjcmlwdDpcbiAgICAgIHJlZ2V4OiAvXFwuanMkL2lcbiAgICAgIG1pbWU6IFwidGV4dC9qYXZhc2NyaXB0XCJcbiAgICBjb2ZmZWU6XG4gICAgICByZWdleDogL1xcLmNvZmZlZSQvaVxuICAgICAgbWltZTogXCJ0ZXh0L2NvZmZlZVwiXG4gICAgY3NzOlxuICAgICAgcmVnZXg6IC9cXC5jc3MkL2lcbiAgICAgIG1pbWU6IFwidGV4dC9jc3NcIlxuICAgIHRleHQ6XG4gICAgICByZWdleDogL1xcLnR4dCQvXG4gICAgICBtaW1lOiBcInRleHQvcGxhaW5cIlxuICBcbiAgZm9yIG5hbWUsIHR5cGUgb2YgdHlwZXNcbiAgICB0eXBlLm5hbWUgPSBuYW1lXG4gIFxuICB0eXBlczogdHlwZXNcbiAgZ2V0QnlGaWxlbmFtZTogKGZpbGVuYW1lKSAtPlxuICAgIGZvciBuYW1lLCBtb2RlIG9mIHR5cGVzXG4gICAgICBpZiBtb2RlLnJlZ2V4LnRlc3QoZmlsZW5hbWUpIHRoZW4gcmV0dXJuIG1vZGVcbiAgICBcbiAgICByZXR1cm4gdHlwZXMudGV4dFxuXG5cbiIsIm1vZHVsZSA9IGFuZ3VsYXIubW9kdWxlIFwicGx1bmtlci5zZXJ2aWNlLnVybFwiLCBbXVxuXG5tb2R1bGUuY29uc3RhbnQgXCJ1cmxcIiwgX3BsdW5rZXIudXJsIiwiLyoqXHJcbiAqIE9wZXJhdGl2ZVxyXG4gKiAtLS1cclxuICogT3BlcmF0aXZlIGlzIGEgc21hbGwgSlMgdXRpbGl0eSBmb3Igc2VhbWxlc3NseSBjcmVhdGluZyBXZWIgV29ya2VyIHNjcmlwdHMuXHJcbiAqIC0tLVxyXG4gKiBAYXV0aG9yIEphbWVzIFBhZG9sc2V5IGh0dHA6Ly9qYW1lcy5wYWRvbHNleS5jb21cclxuICogQHJlcG8gaHR0cDovL2dpdGh1Yi5jb20vcGFkb2xzZXkvb3BlcmF0aXZlXHJcbiAqIEB2ZXJzaW9uIDAuMi4xXHJcbiAqIEBsaWNlbnNlIE1JVFxyXG4gKi9cclxuKGZ1bmN0aW9uKCkge1xyXG5cclxuXHRpZiAodHlwZW9mIHdpbmRvdyA9PSAndW5kZWZpbmVkJyAmJiBzZWxmLmltcG9ydFNjcmlwdHMpIHtcclxuXHRcdC8vIEknbSBhIHdvcmtlciEgUnVuIHRoZSBib2lsZXItc2NyaXB0OlxyXG5cdFx0Ly8gKE9wZXJhdGl2ZSBpdHNlbGYgaXMgY2FsbGVkIGluIElFMTAgYXMgYSB3b3JrZXIsXHJcblx0XHQvLyAgdG8gYXZvaWQgU2VjdXJpdHlFcnJvcnMpXHJcblx0XHR3b3JrZXJCb2lsZXJTY3JpcHQoKTtcclxuXHRcdHJldHVybjtcclxuXHR9XHJcblxyXG5cdHZhciBzbGljZSA9IFtdLnNsaWNlO1xyXG5cdHZhciBoYXNPd24gPSB7fS5oYXNPd25Qcm9wZXJ0eTtcclxuXHJcblx0dmFyIHNjcmlwdHMgPSBkb2N1bWVudC5nZXRFbGVtZW50c0J5VGFnTmFtZSgnc2NyaXB0Jyk7XHJcblx0dmFyIG9wU2NyaXB0ID0gc2NyaXB0c1tzY3JpcHRzLmxlbmd0aCAtIDFdO1xyXG5cdHZhciBvcFNjcmlwdFVSTCA9IC9vcGVyYXRpdmUvLnRlc3Qob3BTY3JpcHQuc3JjKSAmJiBvcFNjcmlwdC5zcmM7XHJcblxyXG5cdC8vIERlZmF1bHQgYmFzZSBVUkwgKHRvIGJlIHByZXBlbmRlZCB0byByZWxhdGl2ZSBkZXBlbmRlbmN5IFVSTHMpXHJcblx0Ly8gaXMgY3VycmVudCBwYWdlJ3MgcGFyZW50IGRpcjpcclxuXHR2YXIgYmFzZVVSTCA9IChcclxuXHRcdGxvY2F0aW9uLnByb3RvY29sICsgJy8vJyArXHJcblx0XHRsb2NhdGlvbi5ob3N0bmFtZSArXHJcblx0XHQobG9jYXRpb24ucG9ydD8nOicrbG9jYXRpb24ucG9ydDonJykgK1xyXG5cdFx0bG9jYXRpb24ucGF0aG5hbWVcclxuXHQpLnJlcGxhY2UoL1teXFwvXSskLywgJycpO1xyXG5cclxuXHR2YXIgVVJMID0gd2luZG93LlVSTCB8fCB3aW5kb3cud2Via2l0VVJMO1xyXG5cdHZhciBCbG9iQnVpbGRlciA9IHdpbmRvdy5CbG9iQnVpbGRlciB8fCB3aW5kb3cuV2ViS2l0QmxvYkJ1aWxkZXIgfHwgd2luZG93Lk1vekJsb2JCdWlsZGVyO1xyXG5cclxuXHR2YXIgd29ya2VyVmlhQmxvYlN1cHBvcnQgPSAoZnVuY3Rpb24oKSB7XHJcblx0XHR0cnkge1xyXG5cdFx0XHRuZXcgV29ya2VyKG1ha2VCbG9iVVJJKCc7JykpO1xyXG5cdFx0fSBjYXRjaChlKSB7XHJcblx0XHRcdHJldHVybiBmYWxzZTtcclxuXHRcdH1cclxuXHRcdHJldHVybiB0cnVlO1xyXG5cdH0oKSk7XHJcblxyXG5cdC8qKlxyXG5cdCAqIFByb3ZpZGUgT2JqZWN0LmNyZWF0ZSBzaGltXHJcblx0ICovXHJcblx0dmFyIG9iakNyZWF0ZSA9IE9iamVjdC5jcmVhdGUgfHwgZnVuY3Rpb24obykge1xyXG5cdFx0ZnVuY3Rpb24gRigpIHt9XHJcblx0XHRGLnByb3RvdHlwZSA9IG87XHJcblx0XHRyZXR1cm4gbmV3IEYoKTtcclxuXHR9O1xyXG5cclxuXHRmdW5jdGlvbiBtYWtlQmxvYlVSSShzY3JpcHQpIHtcclxuXHRcdHZhciBibG9iO1xyXG5cclxuXHRcdHRyeSB7XHJcblx0XHRcdGJsb2IgPSBuZXcgQmxvYihbc2NyaXB0XSwgeyB0eXBlOiAndGV4dC9qYXZhc2NyaXB0JyB9KTtcclxuXHRcdH0gY2F0Y2ggKGUpIHsgXHJcblx0XHRcdGJsb2IgPSBuZXcgQmxvYkJ1aWxkZXIoKTtcclxuXHRcdFx0YmxvYi5hcHBlbmQoc2NyaXB0KTtcclxuXHRcdFx0YmxvYiA9IGJsb2IuZ2V0QmxvYigpO1xyXG5cdFx0fVxyXG5cclxuXHRcdHJldHVybiBVUkwuY3JlYXRlT2JqZWN0VVJMKGJsb2IpO1xyXG5cdH1cclxuXHJcblx0Ly8gSW5kaWNhdGVzIHdoZXRoZXIgb3BlcmF0aXZlcyB3aWxsIHJ1biB3aXRoaW4gd29ya2VyczpcclxuXHRvcGVyYXRpdmUuaGFzV29ya2VyU3VwcG9ydCA9ICEhd2luZG93LldvcmtlcjtcclxuXHJcblx0b3BlcmF0aXZlLlByb21pc2UgPSB3aW5kb3cuUHJvbWlzZTtcclxuXHJcblx0Ly8gRXhwb3NlOlxyXG5cdGlmICh0eXBlb2YgbW9kdWxlICE9PSAndW5kZWZpbmVkJyAmJiBtb2R1bGUuZXhwb3J0cykge1xyXG5cdFx0bW9kdWxlLmV4cG9ydHMgPSBvcGVyYXRpdmU7XHJcblx0fSBlbHNlIHtcclxuXHRcdHdpbmRvdy5vcGVyYXRpdmUgPSBvcGVyYXRpdmU7XHJcblx0fVxyXG5cdFxyXG5cclxuXHRvcGVyYXRpdmUuc2V0U2VsZlVSTCA9IGZ1bmN0aW9uKHVybCkge1xyXG5cdFx0b3BTY3JpcHRVUkwgPSB1cmw7XHJcblx0fTtcclxuXHJcblx0b3BlcmF0aXZlLnNldEJhc2VVUkwgPSBmdW5jdGlvbihiYXNlKSB7XHJcblx0XHRiYXNlVVJMID0gYmFzZTtcclxuXHR9O1xyXG5cclxuXHRvcGVyYXRpdmUuZ2V0QmFzZVVSTCA9IGZ1bmN0aW9uKCkge1xyXG5cdFx0cmV0dXJuIGJhc2VVUkw7XHJcblx0fTtcclxuXHJcblx0LyoqXHJcblx0ICogT3BlcmF0aXZlOiBFeHBvc2VkIE9wZXJhdGl2ZSBDb25zdHJ1Y3RvclxyXG5cdCAqIEBwYXJhbSB7T2JqZWN0fSBtb2R1bGUgT2JqZWN0IGNvbnRhaW5pbmcgbWV0aG9kcy9wcm9wZXJ0aWVzXHJcblx0ICovXHJcblx0ZnVuY3Rpb24gT3BlcmF0aXZlKG1vZHVsZSwgZGVwZW5kZW5jaWVzKSB7XHJcblxyXG5cdFx0dmFyIF9zZWxmID0gdGhpcztcclxuXHJcblx0XHRtb2R1bGUuZ2V0ID0gbW9kdWxlLmdldCB8fCBmdW5jdGlvbihwcm9wKSB7XHJcblx0XHRcdHJldHVybiB0aGlzW3Byb3BdO1xyXG5cdFx0fTtcclxuXHJcblx0XHRtb2R1bGUuc2V0ID0gbW9kdWxlLnNldCB8fCBmdW5jdGlvbihwcm9wLCB2YWx1ZSkge1xyXG5cdFx0XHRyZXR1cm4gdGhpc1twcm9wXSA9IHZhbHVlO1xyXG5cdFx0fTtcclxuXHJcblx0XHR0aGlzLl9jdXJUb2tlbiA9IDA7XHJcblx0XHR0aGlzLl9xdWV1ZSA9IFtdO1xyXG5cclxuXHRcdHRoaXMuaXNEZXN0cm95ZWQgPSBmYWxzZTtcclxuXHRcdHRoaXMuaXNDb250ZXh0UmVhZHkgPSBmYWxzZTtcclxuXHJcblx0XHR0aGlzLm1vZHVsZSA9IG1vZHVsZTtcclxuXHRcdHRoaXMuZGVwZW5kZW5jaWVzID0gZGVwZW5kZW5jaWVzIHx8IFtdO1xyXG5cclxuXHRcdHRoaXMuZGF0YVByb3BlcnRpZXMgPSB7fTtcclxuXHRcdHRoaXMuYXBpID0ge307XHJcblx0XHR0aGlzLmNhbGxiYWNrcyA9IHt9O1xyXG5cdFx0dGhpcy5kZWZlcnJlZHMgPSB7fTtcclxuXHJcblx0XHR0aGlzLl9maXhEZXBlbmRlbmN5VVJMcygpO1xyXG5cdFx0dGhpcy5fc2V0dXAoKTtcclxuXHJcblx0XHRmb3IgKHZhciBtZXRob2ROYW1lIGluIG1vZHVsZSkge1xyXG5cdFx0XHRpZiAoaGFzT3duLmNhbGwobW9kdWxlLCBtZXRob2ROYW1lKSkge1xyXG5cdFx0XHRcdHRoaXMuX2NyZWF0ZUV4cG9zZWRNZXRob2QobWV0aG9kTmFtZSk7XHJcblx0XHRcdH1cclxuXHRcdH1cclxuXHJcblx0XHR0aGlzLmFwaS5fX29wZXJhdGl2ZV9fID0gdGhpcztcclxuXHJcblx0XHQvLyBQcm92aWRlIHRoZSBpbnN0YW5jZSdzIGRlc3Ryb3kgbWV0aG9kIG9uIHRoZSBleHBvc2VkIEFQSTpcclxuXHRcdHRoaXMuYXBpLmRlc3Ryb3kgPSBmdW5jdGlvbigpIHtcclxuXHRcdFx0cmV0dXJuIF9zZWxmLmRlc3Ryb3koKTtcclxuXHRcdH07XHJcblxyXG5cdH1cclxuXHJcblx0T3BlcmF0aXZlLnByb3RvdHlwZSA9IHtcclxuXHJcblx0XHRfbWFyc2hhbDogZnVuY3Rpb24odikge1xyXG5cdFx0XHRyZXR1cm4gdjtcclxuXHRcdH0sXHJcblxyXG5cdFx0X2RlbWFyc2hhbDogZnVuY3Rpb24odikge1xyXG5cdFx0XHRyZXR1cm4gdjtcclxuXHRcdH0sXHJcblxyXG5cdFx0X2VucXVldWU6IGZ1bmN0aW9uKGZuKSB7XHJcblx0XHRcdHRoaXMuX3F1ZXVlLnB1c2goZm4pO1xyXG5cdFx0fSxcclxuXHJcblx0XHRfZml4RGVwZW5kZW5jeVVSTHM6IGZ1bmN0aW9uKCkge1xyXG5cdFx0XHR2YXIgZGVwcyA9IHRoaXMuZGVwZW5kZW5jaWVzO1xyXG5cdFx0XHRmb3IgKHZhciBpID0gMCwgbCA9IGRlcHMubGVuZ3RoOyBpIDwgbDsgKytpKSB7XHJcblx0XHRcdFx0dmFyIGRlcCA9IGRlcHNbaV07XHJcblx0XHRcdFx0aWYgKCEvXFwvXFwvLy50ZXN0KGRlcCkpIHtcclxuXHRcdFx0XHRcdGRlcHNbaV0gPSBkZXAucmVwbGFjZSgvXlxcLz8vLCBiYXNlVVJMKTtcclxuXHRcdFx0XHR9XHJcblx0XHRcdH1cclxuXHRcdH0sXHJcblxyXG5cdFx0X2RlcXVldWVBbGw6IGZ1bmN0aW9uKCkge1xyXG5cdFx0XHRmb3IgKHZhciBpID0gMCwgbCA9IHRoaXMuX3F1ZXVlLmxlbmd0aDsgaSA8IGw7ICsraSkge1xyXG5cdFx0XHRcdHRoaXMuX3F1ZXVlW2ldLmNhbGwodGhpcyk7XHJcblx0XHRcdH1cclxuXHRcdFx0dGhpcy5fcXVldWUgPSBbXTtcclxuXHRcdH0sXHJcblxyXG5cdFx0X2J1aWxkQ29udGV4dFNjcmlwdDogZnVuY3Rpb24oYm9pbGVyU2NyaXB0KSB7XHJcblxyXG5cdFx0XHR2YXIgc2NyaXB0ID0gW107XHJcblx0XHRcdHZhciBtb2R1bGUgPSB0aGlzLm1vZHVsZTtcclxuXHRcdFx0dmFyIGRhdGFQcm9wZXJ0aWVzID0gdGhpcy5kYXRhUHJvcGVydGllcztcclxuXHRcdFx0dmFyIHByb3BlcnR5O1xyXG5cclxuXHRcdFx0Zm9yICh2YXIgaSBpbiBtb2R1bGUpIHtcclxuXHRcdFx0XHRwcm9wZXJ0eSA9IG1vZHVsZVtpXTtcclxuXHRcdFx0XHRpZiAodHlwZW9mIHByb3BlcnR5ID09ICdmdW5jdGlvbicpIHtcclxuXHRcdFx0XHRcdHNjcmlwdC5wdXNoKCcgICBzZWxmW1wiJyArIGkucmVwbGFjZSgvXCIvZywgJ1xcXFxcIicpICsgJ1wiXSA9ICcgKyBwcm9wZXJ0eS50b1N0cmluZygpICsgJzsnKTtcclxuXHRcdFx0XHR9IGVsc2Uge1xyXG5cdFx0XHRcdFx0ZGF0YVByb3BlcnRpZXNbaV0gPSBwcm9wZXJ0eTtcclxuXHRcdFx0XHR9XHJcblx0XHRcdH1cclxuXHJcblx0XHRcdHJldHVybiBzY3JpcHQuam9pbignXFxuJykgKyAoXHJcblx0XHRcdFx0Ym9pbGVyU2NyaXB0ID8gJ1xcbignICsgYm9pbGVyU2NyaXB0LnRvU3RyaW5nKCkgKyAnKCkpOycgOiAnJ1xyXG5cdFx0XHQpO1xyXG5cclxuXHRcdH0sXHJcblxyXG5cdFx0X2NyZWF0ZUV4cG9zZWRNZXRob2Q6IGZ1bmN0aW9uKG1ldGhvZE5hbWUpIHtcclxuXHJcblx0XHRcdHZhciBzZWxmID0gdGhpcztcclxuXHJcblx0XHRcdHRoaXMuYXBpW21ldGhvZE5hbWVdID0gZnVuY3Rpb24oKSB7XHJcblxyXG5cdFx0XHRcdGlmIChzZWxmLmlzRGVzdHJveWVkKSB7XHJcblx0XHRcdFx0XHR0aHJvdyBuZXcgRXJyb3IoJ09wZXJhdGl2ZTogQ2Fubm90IHJ1biBtZXRob2QuIE9wZXJhdGl2ZSBoYXMgYWxyZWFkeSBiZWVuIGRlc3Ryb3llZCcpO1xyXG5cdFx0XHRcdH1cclxuXHJcblx0XHRcdFx0dmFyIHRva2VuID0gKytzZWxmLl9jdXJUb2tlbjtcclxuXHRcdFx0XHR2YXIgYXJncyA9IHNsaWNlLmNhbGwoYXJndW1lbnRzKTtcclxuXHRcdFx0XHR2YXIgY2IgPSB0eXBlb2YgYXJnc1thcmdzLmxlbmd0aCAtIDFdID09ICdmdW5jdGlvbicgJiYgYXJncy5wb3AoKTtcclxuXHJcblx0XHRcdFx0aWYgKCFjYiAmJiAhb3BlcmF0aXZlLlByb21pc2UpIHtcclxuXHRcdFx0XHRcdHRocm93IG5ldyBFcnJvcihcclxuXHRcdFx0XHRcdFx0J09wZXJhdGl2ZTogTm8gY2FsbGJhY2sgaGFzIGJlZW4gcGFzc2VkLiBBc3N1bWVkIHRoYXQgeW91IHdhbnQgYSBwcm9taXNlLiAnICtcclxuXHRcdFx0XHRcdFx0J0J1dCBgb3BlcmF0aXZlLlByb21pc2VgIGlzIG51bGwuIFBsZWFzZSBwcm92aWRlIFByb21pc2UgcG9seWZpbGwvbGliLidcclxuXHRcdFx0XHRcdCk7XHJcblx0XHRcdFx0fVxyXG5cclxuXHRcdFx0XHRpZiAoY2IpIHtcclxuXHJcblx0XHRcdFx0XHRzZWxmLmNhbGxiYWNrc1t0b2tlbl0gPSBjYjtcclxuXHJcblx0XHRcdFx0XHQvLyBFbnN1cmUgZWl0aGVyIGNvbnRleHQgcnVucyB0aGUgbWV0aG9kIGFzeW5jOlxyXG5cdFx0XHRcdFx0c2V0VGltZW91dChmdW5jdGlvbigpIHtcclxuXHRcdFx0XHRcdFx0cnVuTWV0aG9kKCk7XHJcblx0XHRcdFx0XHR9LCAxKTtcclxuXHJcblx0XHRcdFx0fSBlbHNlIGlmIChvcGVyYXRpdmUuUHJvbWlzZSkge1xyXG5cclxuXHRcdFx0XHRcdC8vIE5vIENhbGxiYWNrIC0tIFByb21pc2UgdXNlZDpcclxuXHJcblx0XHRcdFx0XHRyZXR1cm4gbmV3IG9wZXJhdGl2ZS5Qcm9taXNlKGZ1bmN0aW9uKGRlZmVycmVkKSB7XHJcblx0XHRcdFx0XHRcdGRlZmVycmVkLmZ1bGZpbCA9IGRlZmVycmVkLmZ1bGZpbGw7XHJcblx0XHRcdFx0XHRcdHNlbGYuZGVmZXJyZWRzW3Rva2VuXSA9IGRlZmVycmVkO1xyXG5cdFx0XHRcdFx0XHRydW5NZXRob2QoKTtcclxuXHRcdFx0XHRcdH0pO1xyXG5cclxuXHRcdFx0XHR9XHJcblxyXG5cdFx0XHRcdGZ1bmN0aW9uIHJ1bk1ldGhvZCgpIHtcclxuXHRcdFx0XHRcdGlmIChzZWxmLmlzQ29udGV4dFJlYWR5KSB7XHJcblx0XHRcdFx0XHRcdHNlbGYuX3J1bk1ldGhvZChtZXRob2ROYW1lLCB0b2tlbiwgYXJncyk7XHJcblx0XHRcdFx0XHR9IGVsc2Uge1xyXG5cdFx0XHRcdFx0XHRzZWxmLl9lbnF1ZXVlKHJ1bk1ldGhvZCk7XHJcblx0XHRcdFx0XHR9XHJcblx0XHRcdFx0fVxyXG5cclxuXHRcdFx0fTtcclxuXHJcblx0XHR9LFxyXG5cclxuXHRcdGRlc3Ryb3k6IGZ1bmN0aW9uKCkge1xyXG5cdFx0XHR0aGlzLmlzRGVzdHJveWVkID0gdHJ1ZTtcclxuXHRcdH1cclxuXHR9O1xyXG5cclxuXHJcblx0LyoqXHJcblx0ICogT3BlcmF0aXZlIFdvcmtlclxyXG5cdCAqL1xyXG5cdE9wZXJhdGl2ZS5Xb3JrZXIgPSBmdW5jdGlvbiBXb3JrZXIobW9kdWxlKSB7XHJcblx0XHR0aGlzLl9tc2dRdWV1ZSA9IFtdO1xyXG5cdFx0T3BlcmF0aXZlLmFwcGx5KHRoaXMsIGFyZ3VtZW50cyk7XHJcblx0fTtcclxuXHJcblx0dmFyIFdvcmtlclByb3RvID0gT3BlcmF0aXZlLldvcmtlci5wcm90b3R5cGUgPSBvYmpDcmVhdGUoT3BlcmF0aXZlLnByb3RvdHlwZSk7XHJcblxyXG5cdFdvcmtlclByb3RvLl9vbldvcmtlck1lc3NhZ2UgPSBmdW5jdGlvbihlKSB7XHJcblx0XHR2YXIgZGF0YSA9IGUuZGF0YTtcclxuXHJcblx0XHRpZiAodHlwZW9mIGRhdGEgPT09ICdzdHJpbmcnICYmIGRhdGEuaW5kZXhPZigncGluZ2JhY2snKSA9PT0gMCkge1xyXG5cdFx0XHRpZiAoZGF0YSA9PT0gJ3BpbmdiYWNrOnN0cnVjdHVyZWRDbG9uaW5nU3VwcG9ydD1OTycpIHtcclxuXHRcdFx0XHQvLyBObyBzdHJ1Y3R1cmVkQ2xvbmluZ1N1cHBvcnQgc3VwcG9ydCAobWFyc2hhbCBKU09OIGZyb20gbm93IG9uKTpcclxuXHRcdFx0XHR0aGlzLl9tYXJzaGFsID0gZnVuY3Rpb24obykgeyByZXR1cm4gSlNPTi5zdHJpbmdpZnkobyk7IH07XHJcblx0XHRcdFx0dGhpcy5fZGVtYXJzaGFsID0gZnVuY3Rpb24obykgeyByZXR1cm4gSlNPTi5wYXJzZShvKTsgfTtcclxuXHRcdFx0fVxyXG5cclxuXHRcdFx0dGhpcy5pc0NvbnRleHRSZWFkeSA9IHRydWU7XHJcblx0XHRcdHRoaXMuX3Bvc3RNZXNzYWdlKHtcclxuXHRcdFx0XHRkZWZpbml0aW9uczogdGhpcy5kYXRhUHJvcGVydGllc1xyXG5cdFx0XHR9KTtcclxuXHRcdFx0dGhpcy5fZGVxdWV1ZUFsbCgpO1xyXG5cdFx0XHRyZXR1cm47XHJcblxyXG5cdFx0fVxyXG5cclxuXHRcdGRhdGEgPSB0aGlzLl9kZW1hcnNoYWwoZGF0YSk7XHJcblxyXG5cdFx0c3dpdGNoIChkYXRhLmNtZCkge1xyXG5cdFx0XHRjYXNlICdjb25zb2xlJzpcclxuXHRcdFx0XHR3aW5kb3cuY29uc29sZSAmJiB3aW5kb3cuY29uc29sZVtkYXRhLm1ldGhvZF0uYXBwbHkod2luZG93LmNvbnNvbGUsIGRhdGEuYXJncyk7XHJcblx0XHRcdFx0YnJlYWs7XHJcblx0XHRcdGNhc2UgJ3Jlc3VsdCc6XHJcblxyXG5cdFx0XHRcdHZhciBjYWxsYmFjayA9IHRoaXMuY2FsbGJhY2tzW2RhdGEudG9rZW5dO1xyXG5cdFx0XHRcdHZhciBkZWZlcnJlZCA9IHRoaXMuZGVmZXJyZWRzW2RhdGEudG9rZW5dO1xyXG5cclxuXHRcdFx0XHRkZWxldGUgdGhpcy5jYWxsYmFja3NbZGF0YS50b2tlbl07XHJcblx0XHRcdFx0ZGVsZXRlIHRoaXMuZGVmZXJyZWRzW2RhdGEudG9rZW5dO1xyXG5cclxuXHRcdFx0XHR2YXIgZGVmZXJyZWRBY3Rpb24gPSBkYXRhLnJlc3VsdCAmJiBkYXRhLnJlc3VsdC5pc0RlZmVycmVkICYmIGRhdGEucmVzdWx0LmFjdGlvbjtcclxuXHJcblx0XHRcdFx0aWYgKGRlZmVycmVkICYmIGRlZmVycmVkQWN0aW9uKSB7XHJcblx0XHRcdFx0XHRkZWZlcnJlZFtkZWZlcnJlZEFjdGlvbl0oZGF0YS5yZXN1bHQuYXJnc1swXSk7XHJcblx0XHRcdFx0fSBlbHNlIGlmIChjYWxsYmFjaykge1xyXG5cdFx0XHRcdFx0Y2FsbGJhY2suYXBwbHkodGhpcywgZGF0YS5yZXN1bHQuYXJncyk7XHJcblx0XHRcdFx0fVxyXG5cclxuXHRcdFx0XHRicmVhaztcclxuXHRcdH1cclxuXHR9O1xyXG5cclxuXHRXb3JrZXJQcm90by5fc2V0dXAgPSBmdW5jdGlvbigpIHtcclxuXHRcdHZhciBzZWxmID0gdGhpcztcclxuXHJcblx0XHR2YXIgd29ya2VyO1xyXG5cdFx0dmFyIHNjcmlwdCA9IHRoaXMuX2J1aWxkQ29udGV4dFNjcmlwdChcclxuXHRcdFx0Ly8gVGhlIHNjcmlwdCBpcyBub3QgaW5jbHVkZWQgaWYgd2UncmUgRXZhbCdpbmcgdGhpcyBmaWxlIGRpcmVjdGx5OlxyXG5cdFx0XHR3b3JrZXJWaWFCbG9iU3VwcG9ydCA/IHdvcmtlckJvaWxlclNjcmlwdCA6ICcnXHJcblx0XHQpO1xyXG5cclxuXHRcdGlmICh0aGlzLmRlcGVuZGVuY2llcy5sZW5ndGgpIHtcclxuXHRcdFx0c2NyaXB0ID0gJ2ltcG9ydFNjcmlwdHMoXCInICsgdGhpcy5kZXBlbmRlbmNpZXMuam9pbignXCIsIFwiJykgKyAnXCIpO1xcbicgKyBzY3JpcHQ7XHJcblx0XHR9XHJcblxyXG5cdFx0aWYgKHdvcmtlclZpYUJsb2JTdXBwb3J0KSB7XHJcblx0XHRcdHdvcmtlciA9IHRoaXMud29ya2VyID0gbmV3IFdvcmtlciggbWFrZUJsb2JVUkkoc2NyaXB0KSApO1xyXG5cdFx0fSAgZWxzZSB7XHJcblx0XHRcdGlmICghb3BTY3JpcHRVUkwpIHtcclxuXHRcdFx0XHR0aHJvdyBuZXcgRXJyb3IoJ09wZXJhcml0dmU6IE5vIG9wZXJhdGl2ZS5qcyBVUkwgYXZhaWxhYmxlLiBQbGVhc2Ugc2V0IHZpYSBvcGVyYXRpdmUuc2V0U2VsZlVSTCguLi4pJyk7XHJcblx0XHRcdH1cclxuXHRcdFx0d29ya2VyID0gdGhpcy53b3JrZXIgPSBuZXcgV29ya2VyKCBvcFNjcmlwdFVSTCApO1xyXG5cdFx0XHQvLyBNYXJzaGFsLWFnbm9zdGljIGluaXRpYWwgbWVzc2FnZSBpcyBib2lsZXItY29kZTpcclxuXHRcdFx0Ly8gKFdlIGRvbid0IHlldCBrbm93IGlmIHN0cnVjdHVyZWQtY2xvbmluZyBpcyBzdXBwb3J0ZWQgc28gd2Ugc2VuZCBhIHN0cmluZylcclxuXHRcdFx0d29ya2VyLnBvc3RNZXNzYWdlKCdFVkFMfCcgKyBzY3JpcHQpO1xyXG5cdFx0fVxyXG5cclxuXHRcdHdvcmtlci5wb3N0TWVzc2FnZShbJ1BJTkcnXSk7IC8vIEluaXRpYWwgUElOR1xyXG5cclxuXHRcdHdvcmtlci5hZGRFdmVudExpc3RlbmVyKCdtZXNzYWdlJywgZnVuY3Rpb24oZSkge1xyXG5cdFx0XHRzZWxmLl9vbldvcmtlck1lc3NhZ2UoZSk7XHJcblx0XHR9KTtcclxuXHR9O1xyXG5cclxuXHRXb3JrZXJQcm90by5fcG9zdE1lc3NhZ2UgPSBmdW5jdGlvbihtc2cpIHtcclxuXHRcdHJldHVybiB0aGlzLndvcmtlci5wb3N0TWVzc2FnZSh0aGlzLl9tYXJzaGFsKG1zZykpO1xyXG5cdH07XHJcblxyXG5cdFdvcmtlclByb3RvLl9ydW5NZXRob2QgPSBmdW5jdGlvbihtZXRob2ROYW1lLCB0b2tlbiwgYXJncykge1xyXG5cdFx0dGhpcy5fcG9zdE1lc3NhZ2Uoe1xyXG5cdFx0XHRtZXRob2Q6IG1ldGhvZE5hbWUsXHJcblx0XHRcdGFyZ3M6IGFyZ3MsXHJcblx0XHRcdHRva2VuOiB0b2tlblxyXG5cdFx0fSk7XHJcblx0fTtcclxuXHJcblx0V29ya2VyUHJvdG8uZGVzdHJveSA9IGZ1bmN0aW9uKCkge1xyXG5cdFx0dGhpcy53b3JrZXIudGVybWluYXRlKCk7XHJcblx0XHRPcGVyYXRpdmUucHJvdG90eXBlLmRlc3Ryb3kuY2FsbCh0aGlzKTtcclxuXHR9O1xyXG5cclxuXHJcblx0LyoqXHJcblx0ICogT3BlcmF0aXZlIElGcmFtZVxyXG5cdCAqL1xyXG5cdE9wZXJhdGl2ZS5JZnJhbWUgPSBmdW5jdGlvbiBJZnJhbWUobW9kdWxlKSB7XHJcblx0XHRPcGVyYXRpdmUuYXBwbHkodGhpcywgYXJndW1lbnRzKTtcclxuXHR9O1xyXG5cclxuXHR2YXIgSWZyYW1lUHJvdG8gPSBPcGVyYXRpdmUuSWZyYW1lLnByb3RvdHlwZSA9IG9iakNyZWF0ZShPcGVyYXRpdmUucHJvdG90eXBlKTtcclxuXHJcblx0dmFyIF9sb2FkZWRNZXRob2ROYW1lSSA9IDA7XHJcblxyXG5cdElmcmFtZVByb3RvLl9zZXR1cCA9IGZ1bmN0aW9uKCkge1xyXG5cclxuXHRcdHZhciBzZWxmID0gdGhpcztcclxuXHRcdHZhciBsb2FkZWRNZXRob2ROYW1lID0gJ19fb3BlcmF0aXZlSUZyYW1lTG9hZGVkJyArICsrX2xvYWRlZE1ldGhvZE5hbWVJO1xyXG5cclxuXHRcdHRoaXMubW9kdWxlLmlzV29ya2VyID0gZmFsc2U7XHJcblxyXG5cdFx0dmFyIGlmcmFtZSA9IHRoaXMuaWZyYW1lID0gZG9jdW1lbnQuYm9keS5hcHBlbmRDaGlsZChcclxuXHRcdFx0ZG9jdW1lbnQuY3JlYXRlRWxlbWVudCgnaWZyYW1lJylcclxuXHRcdCk7XHJcblxyXG5cdFx0aWZyYW1lLnN0eWxlLmRpc3BsYXkgPSAnbm9uZSc7XHJcblxyXG5cdFx0dmFyIGlXaW4gPSB0aGlzLmlmcmFtZVdpbmRvdyA9IGlmcmFtZS5jb250ZW50V2luZG93O1xyXG5cdFx0dmFyIGlEb2MgPSBpV2luLmRvY3VtZW50O1xyXG5cclxuXHRcdC8vIENyb3NzIGJyb3dzZXIgKHRlc3RlZCBpbiBJRTgsOSkgd2F5IHRvIGNhbGwgbWV0aG9kIGZyb20gd2l0aGluXHJcblx0XHQvLyBJRlJBTUUgYWZ0ZXIgYWxsIDxTY3JpcHQ+cyBoYXZlIGxvYWRlZDpcclxuXHRcdHdpbmRvd1tsb2FkZWRNZXRob2ROYW1lXSA9IGZ1bmN0aW9uKCkge1xyXG5cclxuXHRcdFx0d2luZG93W2xvYWRlZE1ldGhvZE5hbWVdID0gbnVsbDtcclxuXHJcblx0XHRcdHZhciBzY3JpcHQgPSBpRG9jLmNyZWF0ZUVsZW1lbnQoJ3NjcmlwdCcpO1xyXG5cdFx0XHR2YXIganMgPSBzZWxmLl9idWlsZENvbnRleHRTY3JpcHQoaWZyYW1lQm9pbGVyU2NyaXB0KTtcclxuXHJcblx0XHRcdGlmIChzY3JpcHQudGV4dCAhPT0gdm9pZCAwKSB7XHJcblx0XHRcdFx0c2NyaXB0LnRleHQgPSBqcztcclxuXHRcdFx0fSBlbHNlIHtcclxuXHRcdFx0XHRzY3JpcHQuaW5uZXJIVE1MID0ganM7XHJcblx0XHRcdH1cclxuXHJcblx0XHRcdGlEb2MuZG9jdW1lbnRFbGVtZW50LmFwcGVuZENoaWxkKHNjcmlwdCk7XHJcblxyXG5cdFx0XHRmb3IgKHZhciBpIGluIHNlbGYuZGF0YVByb3BlcnRpZXMpIHtcclxuXHRcdFx0XHRpV2luW2ldID0gc2VsZi5kYXRhUHJvcGVydGllc1tpXTtcclxuXHRcdFx0fVxyXG5cclxuXHRcdFx0c2VsZi5pc0NvbnRleHRSZWFkeSA9IHRydWU7XHJcblx0XHRcdHNlbGYuX2RlcXVldWVBbGwoKTtcclxuXHJcblx0XHR9O1xyXG5cclxuXHRcdGlEb2Mub3BlbigpO1xyXG5cdFx0aWYgKHRoaXMuZGVwZW5kZW5jaWVzLmxlbmd0aCkge1xyXG5cdFx0XHRpRG9jLndyaXRlKFxyXG5cdFx0XHRcdCc8c2NyaXB0IHNyYz1cIicgKyB0aGlzLmRlcGVuZGVuY2llcy5qb2luKCdcIj48L3NjcmlwdD48c2NyaXB0IHNyYz1cIicpICsgJ1wiPjwvc2NyaXB0PidcclxuXHRcdFx0KTtcclxuXHRcdH1cclxuXHRcdC8vIFBsYWNlIDxzY3JpcHQ+IGF0IGJvdHRvbSB0byB0ZWxsIHBhcmVudC1wYWdlIHdoZW4gZGVwZW5kZW5jaWVzIGFyZSBsb2FkZWQ6XHJcblx0XHRpRG9jLndyaXRlKCc8c2NyaXB0PndpbmRvdy50b3AuJyArIGxvYWRlZE1ldGhvZE5hbWUgKyAnKCk7PC9zY3JpcHQ+Jyk7XHJcblx0XHRpRG9jLmNsb3NlKCk7XHJcblxyXG5cdH07XHJcblxyXG5cdElmcmFtZVByb3RvLl9ydW5NZXRob2QgPSBmdW5jdGlvbihtZXRob2ROYW1lLCB0b2tlbiwgYXJncykge1xyXG5cdFx0dmFyIHNlbGYgPSB0aGlzO1xyXG5cdFx0dmFyIGNhbGxiYWNrID0gdGhpcy5jYWxsYmFja3NbdG9rZW5dO1xyXG5cdFx0dmFyIGRlZmVycmVkID0gdGhpcy5kZWZlcnJlZHNbdG9rZW5dO1xyXG5cdFx0ZGVsZXRlIHRoaXMuY2FsbGJhY2tzW3Rva2VuXTtcclxuXHRcdGRlbGV0ZSB0aGlzLmRlZmVycmVkc1t0b2tlbl07XHJcblx0XHR0aGlzLmlmcmFtZVdpbmRvdy5fX3J1bl9fKG1ldGhvZE5hbWUsIGFyZ3MsIGZ1bmN0aW9uKCkge1xyXG5cdFx0XHR2YXIgY2IgPSBjYWxsYmFjaztcclxuXHRcdFx0aWYgKGNiKSB7XHJcblx0XHRcdFx0Y2FsbGJhY2sgPSBudWxsO1xyXG5cdFx0XHRcdGNiLmFwcGx5KHNlbGYsIGFyZ3VtZW50cyk7XHJcblx0XHRcdH0gZWxzZSB7XHJcblx0XHRcdFx0dGhyb3cgbmV3IEVycm9yKCdPcGVyYXRpdmU6IFlvdSBoYXZlIGFscmVhZHkgcmV0dXJuZWQuJyk7XHJcblx0XHRcdH1cclxuXHRcdH0sIGRlZmVycmVkKTtcclxuXHR9O1xyXG5cclxuXHRJZnJhbWVQcm90by5kZXN0cm95ID0gZnVuY3Rpb24oKSB7XHJcblx0XHR0aGlzLmlmcmFtZS5wYXJlbnROb2RlLnJlbW92ZUNoaWxkKHRoaXMuaWZyYW1lKTtcclxuXHRcdE9wZXJhdGl2ZS5wcm90b3R5cGUuZGVzdHJveS5jYWxsKHRoaXMpO1xyXG5cdH07XHJcblxyXG5cdG9wZXJhdGl2ZS5PcGVyYXRpdmUgPSBPcGVyYXRpdmU7XHJcblxyXG5cdC8qKlxyXG5cdCAqIEV4cG9zZWQgb3BlcmF0aXZlIGZhY3RvcnlcclxuXHQgKi9cclxuXHRmdW5jdGlvbiBvcGVyYXRpdmUobW9kdWxlLCBkZXBlbmRlbmNpZXMpIHtcclxuXHJcblx0XHR2YXIgT3BlcmF0aXZlQ29udGV4dCA9IG9wZXJhdGl2ZS5oYXNXb3JrZXJTdXBwb3J0ID9cclxuXHRcdFx0T3BlcmF0aXZlLldvcmtlciA6IE9wZXJhdGl2ZS5JZnJhbWU7XHJcblxyXG5cdFx0aWYgKHR5cGVvZiBtb2R1bGUgPT0gJ2Z1bmN0aW9uJykge1xyXG5cdFx0XHQvLyBBbGxvdyBhIHNpbmdsZSBmdW5jdGlvbiB0byBiZSBwYXNzZWQuXHJcblx0XHRcdHZhciBvID0gbmV3IE9wZXJhdGl2ZUNvbnRleHQoeyBtYWluOiBtb2R1bGUgfSwgZGVwZW5kZW5jaWVzKTtcclxuXHRcdFx0cmV0dXJuIGZ1bmN0aW9uKCkge1xyXG5cdFx0XHRcdHJldHVybiBvLmFwaS5tYWluLmFwcGx5KG8sIGFyZ3VtZW50cyk7XHJcblx0XHRcdH07XHJcblx0XHR9XHJcblxyXG5cdFx0cmV0dXJuIG5ldyBPcGVyYXRpdmVDb250ZXh0KG1vZHVsZSwgZGVwZW5kZW5jaWVzKS5hcGk7XHJcblxyXG5cdH1cclxuXHJcbi8qKlxyXG4gKiBUaGUgYm9pbGVycGxhdGUgZm9yIHRoZSBJZnJhbWUgQ29udGV4dFxyXG4gKiBOT1RFOlxyXG4gKiAgdGhpcydsbCBiZSBleGVjdXRlZCB3aXRoaW4gYW4gaWZyYW1lLCBub3QgaGVyZS5cclxuICogIEluZGVudGVkIEAgWmVybyB0byBtYWtlIG5pY2VyIGRlYnVnIGNvZGUgd2l0aGluIHdvcmtlclxyXG4gKi9cclxuZnVuY3Rpb24gaWZyYW1lQm9pbGVyU2NyaXB0KCkge1xyXG5cclxuXHQvLyBDYWxsZWQgZnJvbSBwYXJlbnQtd2luZG93OlxyXG5cdHdpbmRvdy5fX3J1bl9fID0gZnVuY3Rpb24obWV0aG9kTmFtZSwgYXJncywgY2IsIGRlZmVycmVkKSB7XHJcblxyXG5cdFx0dmFyIGlzQXN5bmMgPSBmYWxzZTtcclxuXHRcdHZhciBpc0RlZmVycmVkID0gZmFsc2U7XHJcblxyXG5cdFx0d2luZG93LmFzeW5jID0gZnVuY3Rpb24oKSB7XHJcblx0XHRcdGlzQXN5bmMgPSB0cnVlO1xyXG5cdFx0XHRyZXR1cm4gY2I7XHJcblx0XHR9O1xyXG5cclxuXHRcdHdpbmRvdy5kZWZlcnJlZCA9IGZ1bmN0aW9uKCkge1xyXG5cdFx0XHRpc0RlZmVycmVkID0gdHJ1ZTtcclxuXHRcdFx0cmV0dXJuIGRlZmVycmVkO1xyXG5cdFx0fTtcclxuXHJcblx0XHRpZiAoY2IpIHtcclxuXHRcdFx0YXJncy5wdXNoKGNiKTtcclxuXHRcdH1cclxuXHJcblx0XHR2YXIgcmVzdWx0ID0gd2luZG93W21ldGhvZE5hbWVdLmFwcGx5KHdpbmRvdywgYXJncyk7XHJcblxyXG5cdFx0d2luZG93LmFzeW5jID0gZnVuY3Rpb24oKSB7XHJcblx0XHRcdHRocm93IG5ldyBFcnJvcignT3BlcmF0aXZlOiBhc3luYygpIGNhbGxlZCBhdCBvZGQgdGltZScpO1xyXG5cdFx0fTtcclxuXHJcblx0XHR3aW5kb3cuZGVmZXJyZWQgPSBmdW5jdGlvbigpIHtcclxuXHRcdFx0dGhyb3cgbmV3IEVycm9yKCdPcGVyYXRpdmU6IGRlZmVycmVkKCkgY2FsbGVkIGF0IG9kZCB0aW1lJyk7XHJcblx0XHR9O1xyXG5cclxuXHJcblx0XHRpZiAoIWlzRGVmZXJyZWQgJiYgIWlzQXN5bmMgJiYgcmVzdWx0ICE9PSB2b2lkIDApIHtcclxuXHRcdFx0Ly8gRGVwcmVjYXRlZCBkaXJlY3QtcmV0dXJuaW5nIGFzIG9mIDAuMi4wXHJcblx0XHRcdGNiKHJlc3VsdCk7XHJcblx0XHR9XHJcblx0fTtcclxufVxyXG5cclxuLyoqXHJcbiAqIFRoZSBib2lsZXJwbGF0ZSBmb3IgdGhlIFdvcmtlciBCbG9iXHJcbiAqIE5PVEU6XHJcbiAqICB0aGlzJ2xsIGJlIGV4ZWN1dGVkIHdpdGhpbiBhbiBpZnJhbWUsIG5vdCBoZXJlLlxyXG4gKiAgSW5kZW50ZWQgQCBaZXJvIHRvIG1ha2UgbmljZXIgZGVidWcgY29kZSB3aXRoaW4gd29ya2VyXHJcbiAqL1xyXG5mdW5jdGlvbiB3b3JrZXJCb2lsZXJTY3JpcHQoKSB7XHJcblxyXG5cdHZhciBwb3N0TWVzc2FnZSA9IHNlbGYucG9zdE1lc3NhZ2U7XHJcblx0dmFyIHN0cnVjdHVyZWRDbG9uaW5nU3VwcG9ydCA9IG51bGw7XHJcblxyXG5cdHNlbGYuY29uc29sZSA9IHt9O1xyXG5cdHNlbGYuaXNXb3JrZXIgPSB0cnVlO1xyXG5cclxuXHQvLyBQcm92aWRlIGJhc2ljIGNvbnNvbGUgaW50ZXJmYWNlOlxyXG5cdFsnbG9nJywgJ2RlYnVnJywgJ2Vycm9yJywgJ2luZm8nLCAnd2FybicsICd0aW1lJywgJ3RpbWVFbmQnXS5mb3JFYWNoKGZ1bmN0aW9uKG1ldGgpIHtcclxuXHRcdHNlbGYuY29uc29sZVttZXRoXSA9IGZ1bmN0aW9uKCkge1xyXG5cdFx0XHRwb3N0TWVzc2FnZSh7XHJcblx0XHRcdFx0Y21kOiAnY29uc29sZScsXHJcblx0XHRcdFx0bWV0aG9kOiBtZXRoLFxyXG5cdFx0XHRcdGFyZ3M6IFtdLnNsaWNlLmNhbGwoYXJndW1lbnRzKVxyXG5cdFx0XHR9KTtcclxuXHRcdH07XHJcblx0fSk7XHJcblxyXG5cdHNlbGYuYWRkRXZlbnRMaXN0ZW5lcignbWVzc2FnZScsIGZ1bmN0aW9uKGUpIHtcclxuXHJcblx0XHR2YXIgZGF0YSA9IGUuZGF0YTtcclxuXHJcblx0XHRpZiAodHlwZW9mIGRhdGEgPT0gJ3N0cmluZycgJiYgZGF0YS5pbmRleE9mKCdFVkFMfCcpID09PSAwKSB7XHJcblx0XHRcdGV2YWwoZGF0YS5zdWJzdHJpbmcoNSkpO1xyXG5cdFx0XHRyZXR1cm47XHJcblx0XHR9XHJcblxyXG5cdFx0aWYgKHN0cnVjdHVyZWRDbG9uaW5nU3VwcG9ydCA9PSBudWxsKSB7XHJcblxyXG5cdFx0XHQvLyBlLmRhdGEgb2YgWydQSU5HJ10gKEFuIGFycmF5KSBpbmRpY2F0ZXMgdHJhbnNmZXJyYWJsZU9ialN1cHBvcnRcclxuXHRcdFx0Ly8gZS5kYXRhIG9mICdcIlBJTkdcIicgKEEgc3RyaW5nKSBpbmRpY2F0ZXMgbm8gc3VwcG9ydCAoQXJyYXkgaGFzIGJlZW4gc2VyaWFsaXplZClcclxuXHRcdFx0c3RydWN0dXJlZENsb25pbmdTdXBwb3J0ID0gZS5kYXRhWzBdID09PSAnUElORyc7XHJcblxyXG5cdFx0XHQvLyBQaW5nYmFjayB0byBwYXJlbnQgcGFnZTpcclxuXHRcdFx0c2VsZi5wb3N0TWVzc2FnZShcclxuXHRcdFx0XHRzdHJ1Y3R1cmVkQ2xvbmluZ1N1cHBvcnQgP1xyXG5cdFx0XHRcdFx0J3BpbmdiYWNrOnN0cnVjdHVyZWRDbG9uaW5nU3VwcG9ydD1ZRVMnIDpcclxuXHRcdFx0XHRcdCdwaW5nYmFjazpzdHJ1Y3R1cmVkQ2xvbmluZ1N1cHBvcnQ9Tk8nXHJcblx0XHRcdCk7XHJcblxyXG5cdFx0XHRpZiAoIXN0cnVjdHVyZWRDbG9uaW5nU3VwcG9ydCkge1xyXG5cdFx0XHRcdHBvc3RNZXNzYWdlID0gZnVuY3Rpb24obXNnKSB7XHJcblx0XHRcdFx0XHQvLyBNYXJzaGFsIGJlZm9yZSBzZW5kaW5nXHJcblx0XHRcdFx0XHRyZXR1cm4gc2VsZi5wb3N0TWVzc2FnZShKU09OLnN0cmluZ2lmeShtc2cpKTtcclxuXHRcdFx0XHR9O1xyXG5cdFx0XHR9XHJcblxyXG5cdFx0XHRyZXR1cm47XHJcblx0XHR9XHJcblxyXG5cdFx0aWYgKCFzdHJ1Y3R1cmVkQ2xvbmluZ1N1cHBvcnQpIHtcclxuXHRcdFx0Ly8gRGVtYXJzaGFsOlxyXG5cdFx0XHRkYXRhID0gSlNPTi5wYXJzZShkYXRhKTtcclxuXHRcdH1cclxuXHJcblx0XHR2YXIgZGVmcyA9IGRhdGEuZGVmaW5pdGlvbnM7XHJcblx0XHR2YXIgaXNEZWZlcnJlZCA9IGZhbHNlO1xyXG5cdFx0dmFyIGlzQXN5bmMgPSBmYWxzZTtcclxuXHRcdHZhciBhcmdzID0gZGF0YS5hcmdzO1xyXG5cclxuXHRcdGlmIChkZWZzKSB7XHJcblx0XHRcdC8vIEluaXRpYWwgZGVmaW5pdGlvbnM6XHJcblx0XHRcdGZvciAodmFyIGkgaW4gZGVmcykge1xyXG5cdFx0XHRcdHNlbGZbaV0gPSBkZWZzW2ldO1xyXG5cdFx0XHR9XHJcblx0XHRcdHJldHVybjtcclxuXHRcdH1cclxuXHJcblx0XHRhcmdzLnB1c2goZnVuY3Rpb24oKSB7XHJcblx0XHRcdC8vIENhbGxiYWNrIGZ1bmN0aW9uIHRvIGJlIHBhc3NlZCB0byBvcGVyYXRpdmUgbWV0aG9kXHJcblx0XHRcdHJldHVyblJlc3VsdCh7XHJcblx0XHRcdFx0YXJnczogW10uc2xpY2UuY2FsbChhcmd1bWVudHMpXHJcblx0XHRcdH0pO1xyXG5cdFx0fSk7XHJcblxyXG5cdFx0c2VsZi5hc3luYyA9IGZ1bmN0aW9uKCkgeyAvLyBBc3luYyBkZXByZWNhdGVkIGFzIG9mIDAuMi4wXHJcblx0XHRcdGlzQXN5bmMgPSB0cnVlO1xyXG5cdFx0XHRyZXR1cm4gZnVuY3Rpb24oKSB7IHJldHVyblJlc3VsdCh7IGFyZ3M6IFtdLnNsaWNlLmNhbGwoYXJndW1lbnRzKSB9KTsgfTtcclxuXHRcdH07XHJcblxyXG5cdFx0c2VsZi5kZWZlcnJlZCA9IGZ1bmN0aW9uKCkge1xyXG5cdFx0XHRpc0RlZmVycmVkID0gdHJ1ZTtcclxuXHRcdFx0dmFyIGRlZiA9IHt9O1xyXG5cdFx0XHRmdW5jdGlvbiBmdWxmaWxsKHIpIHtcclxuXHRcdFx0XHRyZXR1cm5SZXN1bHQoe1xyXG5cdFx0XHRcdFx0aXNEZWZlcnJlZDogdHJ1ZSxcclxuXHRcdFx0XHRcdGFjdGlvbjogJ2Z1bGZpbGwnLFxyXG5cdFx0XHRcdFx0YXJnczogW3JdXHJcblx0XHRcdFx0fSk7XHJcblx0XHRcdFx0cmV0dXJuIGRlZjtcclxuXHRcdFx0fVxyXG5cdFx0XHRmdW5jdGlvbiByZWplY3Qocikge1xyXG5cdFx0XHRcdHJldHVyblJlc3VsdCh7XHJcblx0XHRcdFx0XHRpc0RlZmVycmVkOiB0cnVlLFxyXG5cdFx0XHRcdFx0YWN0aW9uOiAncmVqZWN0JyxcclxuXHRcdFx0XHRcdGFyZ3M6IFtyXVxyXG5cdFx0XHRcdH0pO1xyXG5cdFx0XHR9XHJcblx0XHRcdGRlZi5mdWxmaWwgPSBkZWYuZnVsZmlsbCA9IGZ1bGZpbGw7XHJcblx0XHRcdGRlZi5yZWplY3QgPSByZWplY3Q7XHJcblx0XHRcdHJldHVybiBkZWY7XHJcblx0XHR9O1xyXG5cclxuXHRcdC8vIENhbGwgYWN0dWFsIG9wZXJhdGl2ZSBtZXRob2Q6XHJcblx0XHR2YXIgcmVzdWx0ID0gc2VsZltkYXRhLm1ldGhvZF0uYXBwbHkoc2VsZiwgYXJncyk7XHJcblxyXG5cdFx0aWYgKCFpc0RlZmVycmVkICYmICFpc0FzeW5jICYmIHJlc3VsdCAhPT0gdm9pZCAwKSB7XHJcblx0XHRcdC8vIERlcHJlY2F0ZWQgZGlyZWN0LXJldHVybmluZyBhcyBvZiAwLjIuMFxyXG5cdFx0XHRyZXR1cm5SZXN1bHQoe1xyXG5cdFx0XHRcdGFyZ3M6IFtyZXN1bHRdXHJcblx0XHRcdH0pO1xyXG5cdFx0fVxyXG5cclxuXHRcdHNlbGYuZGVmZXJyZWQgPSBmdW5jdGlvbigpIHtcclxuXHRcdFx0dGhyb3cgbmV3IEVycm9yKCdPcGVyYXRpdmU6IGRlZmVycmVkKCkgY2FsbGVkIGF0IG9kZCB0aW1lJyk7XHJcblx0XHR9O1xyXG5cclxuXHRcdHNlbGYuYXN5bmMgPSBmdW5jdGlvbigpIHsgLy8gQXN5bmMgZGVwcmVjYXRlZCBhcyBvZiAwLjIuMFxyXG5cdFx0XHR0aHJvdyBuZXcgRXJyb3IoJ09wZXJhdGl2ZTogYXN5bmMoKSBjYWxsZWQgYXQgb2RkIHRpbWUnKTtcclxuXHRcdH07XHJcblxyXG5cdFx0ZnVuY3Rpb24gcmV0dXJuUmVzdWx0KHJlcykge1xyXG5cdFx0XHRwb3N0TWVzc2FnZSh7XHJcblx0XHRcdFx0Y21kOiAncmVzdWx0JyxcclxuXHRcdFx0XHR0b2tlbjogZGF0YS50b2tlbixcclxuXHRcdFx0XHRyZXN1bHQ6IHJlc1xyXG5cdFx0XHR9KTtcclxuXHRcdFx0Ly8gT3ZlcnJpZGUgd2l0aCBlcnJvci10aHJvd2VyIGlmIHdlJ3ZlIGFscmVhZHkgcmV0dXJuZWQ6XHJcblx0XHRcdHJldHVyblJlc3VsdCA9IGZ1bmN0aW9uKCkge1xyXG5cdFx0XHRcdHRocm93IG5ldyBFcnJvcignT3BlcmF0aXZlOiBZb3UgaGF2ZSBhbHJlYWR5IHJldHVybmVkLicpO1xyXG5cdFx0XHR9O1xyXG5cdFx0fVxyXG5cdH0pO1xyXG59XHJcblxyXG59KCkpOyIsIi8vIFRoaXMgaXMgYSBwcmVsdWRlIHdoaWNoIGNvbWVzIGJlZm9yZSB0aGUgSlMgYmxvYiBvZiBlYWNoIEpTIHR5cGUgZm9yIHRoZSB3ZWIuXHJcbihmdW5jdGlvbigpe1xyXG4gIHZhciBtb2R1bGUgPSB7ZXhwb3J0czp7fX07XHJcbiAgdmFyIGV4cG9ydHMgPSBtb2R1bGUuZXhwb3J0cztcclxuXHJcbi8vIFRoZXNlIG1ldGhvZHMgbGV0IHlvdSBidWlsZCBhIHRyYW5zZm9ybSBmdW5jdGlvbiBmcm9tIGEgdHJhbnNmb3JtQ29tcG9uZW50XHJcbi8vIGZ1bmN0aW9uIGZvciBPVCB0eXBlcyBsaWtlIEpTT04wIGluIHdoaWNoIG9wZXJhdGlvbnMgYXJlIGxpc3RzIG9mIGNvbXBvbmVudHNcclxuLy8gYW5kIHRyYW5zZm9ybWluZyB0aGVtIHJlcXJldWlyZXMgTl4yIHdvcmsuIEkgZmluZCBpdCBraW5kIG9mIG5hc3R5IHRoYXQgSSBuZWVkXHJcbi8vIHRoaXMsIGJ1dCBJJ20gbm90IHJlYWxseSBzdXJlIHdoYXQgYSBiZXR0ZXIgc29sdXRpb24gaXMuIE1heWJlIEkgc2hvdWxkIGRvXHJcbi8vIHRoaXMgYXV0b21hdGljYWxseSB0byB0eXBlcyB0aGF0IGRvbid0IGhhdmUgYSBjb21wb3NlIGZ1bmN0aW9uIGRlZmluZWQuXHJcblxyXG4vLyBBZGQgdHJhbnNmb3JtIGFuZCB0cmFuc2Zvcm1YIGZ1bmN0aW9ucyBmb3IgYW4gT1QgdHlwZSB3aGljaCBoYXNcclxuLy8gdHJhbnNmb3JtQ29tcG9uZW50IGRlZmluZWQuICB0cmFuc2Zvcm1Db21wb25lbnQoZGVzdGluYXRpb24gYXJyYXksXHJcbi8vIGNvbXBvbmVudCwgb3RoZXIgY29tcG9uZW50LCBzaWRlKVxyXG5leHBvcnRzLl9ib290c3RyYXBUcmFuc2Zvcm0gPSBmdW5jdGlvbih0eXBlLCB0cmFuc2Zvcm1Db21wb25lbnQsIGNoZWNrVmFsaWRPcCwgYXBwZW5kKSB7XHJcbiAgdmFyIHRyYW5zZm9ybUNvbXBvbmVudFggPSBmdW5jdGlvbihsZWZ0LCByaWdodCwgZGVzdExlZnQsIGRlc3RSaWdodCkge1xyXG4gICAgdHJhbnNmb3JtQ29tcG9uZW50KGRlc3RMZWZ0LCBsZWZ0LCByaWdodCwgJ2xlZnQnKTtcclxuICAgIHRyYW5zZm9ybUNvbXBvbmVudChkZXN0UmlnaHQsIHJpZ2h0LCBsZWZ0LCAncmlnaHQnKTtcclxuICB9O1xyXG5cclxuICB2YXIgdHJhbnNmb3JtWCA9IHR5cGUudHJhbnNmb3JtWCA9IGZ1bmN0aW9uKGxlZnRPcCwgcmlnaHRPcCkge1xyXG4gICAgY2hlY2tWYWxpZE9wKGxlZnRPcCk7XHJcbiAgICBjaGVja1ZhbGlkT3AocmlnaHRPcCk7XHJcbiAgICB2YXIgbmV3UmlnaHRPcCA9IFtdO1xyXG5cclxuICAgIGZvciAodmFyIGkgPSAwOyBpIDwgcmlnaHRPcC5sZW5ndGg7IGkrKykge1xyXG4gICAgICB2YXIgcmlnaHRDb21wb25lbnQgPSByaWdodE9wW2ldO1xyXG5cclxuICAgICAgLy8gR2VuZXJhdGUgbmV3TGVmdE9wIGJ5IGNvbXBvc2luZyBsZWZ0T3AgYnkgcmlnaHRDb21wb25lbnRcclxuICAgICAgdmFyIG5ld0xlZnRPcCA9IFtdO1xyXG4gICAgICB2YXIgayA9IDA7XHJcbiAgICAgIHdoaWxlIChrIDwgbGVmdE9wLmxlbmd0aCkge1xyXG4gICAgICAgIHZhciBuZXh0QyA9IFtdO1xyXG4gICAgICAgIHRyYW5zZm9ybUNvbXBvbmVudFgobGVmdE9wW2tdLCByaWdodENvbXBvbmVudCwgbmV3TGVmdE9wLCBuZXh0Qyk7XHJcbiAgICAgICAgaysrO1xyXG5cclxuICAgICAgICBpZiAobmV4dEMubGVuZ3RoID09PSAxKSB7XHJcbiAgICAgICAgICByaWdodENvbXBvbmVudCA9IG5leHRDWzBdO1xyXG4gICAgICAgIH0gZWxzZSBpZiAobmV4dEMubGVuZ3RoID09PSAwKSB7XHJcbiAgICAgICAgICBmb3IgKHZhciBqID0gazsgaiA8IGxlZnRPcC5sZW5ndGg7IGorKykge1xyXG4gICAgICAgICAgICBhcHBlbmQobmV3TGVmdE9wLCBsZWZ0T3Bbal0pO1xyXG4gICAgICAgICAgfVxyXG4gICAgICAgICAgcmlnaHRDb21wb25lbnQgPSBudWxsO1xyXG4gICAgICAgICAgYnJlYWs7XHJcbiAgICAgICAgfSBlbHNlIHtcclxuICAgICAgICAgIC8vIFJlY3Vyc2UuXHJcbiAgICAgICAgICB2YXIgcGFpciA9IHRyYW5zZm9ybVgobGVmdE9wLnNsaWNlKGspLCBuZXh0Qyk7XHJcbiAgICAgICAgICBmb3IgKHZhciBsID0gMDsgbCA8IHBhaXJbMF0ubGVuZ3RoOyBsKyspIHtcclxuICAgICAgICAgICAgYXBwZW5kKG5ld0xlZnRPcCwgcGFpclswXVtsXSk7XHJcbiAgICAgICAgICB9XHJcbiAgICAgICAgICBmb3IgKHZhciByID0gMDsgciA8IHBhaXJbMV0ubGVuZ3RoOyByKyspIHtcclxuICAgICAgICAgICAgYXBwZW5kKG5ld1JpZ2h0T3AsIHBhaXJbMV1bcl0pO1xyXG4gICAgICAgICAgfVxyXG4gICAgICAgICAgcmlnaHRDb21wb25lbnQgPSBudWxsO1xyXG4gICAgICAgICAgYnJlYWs7XHJcbiAgICAgICAgfVxyXG4gICAgICB9XHJcblxyXG4gICAgICBpZiAocmlnaHRDb21wb25lbnQgIT0gbnVsbCkge1xyXG4gICAgICAgIGFwcGVuZChuZXdSaWdodE9wLCByaWdodENvbXBvbmVudCk7XHJcbiAgICAgIH1cclxuICAgICAgbGVmdE9wID0gbmV3TGVmdE9wO1xyXG4gICAgfVxyXG4gICAgcmV0dXJuIFtsZWZ0T3AsIG5ld1JpZ2h0T3BdO1xyXG4gIH07XHJcblxyXG4gIC8vIFRyYW5zZm9ybXMgb3Agd2l0aCBzcGVjaWZpZWQgdHlwZSAoJ2xlZnQnIG9yICdyaWdodCcpIGJ5IG90aGVyT3AuXHJcbiAgdHlwZS50cmFuc2Zvcm0gPSB0eXBlWyd0cmFuc2Zvcm0nXSA9IGZ1bmN0aW9uKG9wLCBvdGhlck9wLCB0eXBlKSB7XHJcbiAgICBpZiAoISh0eXBlID09PSAnbGVmdCcgfHwgdHlwZSA9PT0gJ3JpZ2h0JykpXHJcbiAgICAgIHRocm93IG5ldyBFcnJvcihcInR5cGUgbXVzdCBiZSAnbGVmdCcgb3IgJ3JpZ2h0J1wiKTtcclxuXHJcbiAgICBpZiAob3RoZXJPcC5sZW5ndGggPT09IDApIHJldHVybiBvcDtcclxuXHJcbiAgICBpZiAob3AubGVuZ3RoID09PSAxICYmIG90aGVyT3AubGVuZ3RoID09PSAxKVxyXG4gICAgICByZXR1cm4gdHJhbnNmb3JtQ29tcG9uZW50KFtdLCBvcFswXSwgb3RoZXJPcFswXSwgdHlwZSk7XHJcblxyXG4gICAgaWYgKHR5cGUgPT09ICdsZWZ0JylcclxuICAgICAgcmV0dXJuIHRyYW5zZm9ybVgob3AsIG90aGVyT3ApWzBdO1xyXG4gICAgZWxzZVxyXG4gICAgICByZXR1cm4gdHJhbnNmb3JtWChvdGhlck9wLCBvcClbMV07XHJcbiAgfTtcclxufTtcclxuLy8gREVQUkVDQVRFRCFcclxuLy9cclxuLy8gVGhpcyB0eXBlIHdvcmtzLCBidXQgaXMgbm90IGV4cG9ydGVkLCBhbmQgd2lsbCBiZSByZW1vdmVkIGluIGEgZnV0dXJlIHZlcnNpb24gb2YgdGhpcyBsaWJyYXJ5LlxyXG5cclxuXHJcbi8vIEEgc2ltcGxlIHRleHQgaW1wbGVtZW50YXRpb25cclxuLy9cclxuLy8gT3BlcmF0aW9ucyBhcmUgbGlzdHMgb2YgY29tcG9uZW50cy5cclxuLy8gRWFjaCBjb21wb25lbnQgZWl0aGVyIGluc2VydHMgb3IgZGVsZXRlcyBhdCBhIHNwZWNpZmllZCBwb3NpdGlvbiBpbiB0aGUgZG9jdW1lbnQuXHJcbi8vXHJcbi8vIENvbXBvbmVudHMgYXJlIGVpdGhlcjpcclxuLy8gIHtpOidzdHInLCBwOjEwMH06IEluc2VydCAnc3RyJyBhdCBwb3NpdGlvbiAxMDAgaW4gdGhlIGRvY3VtZW50XHJcbi8vICB7ZDonc3RyJywgcDoxMDB9OiBEZWxldGUgJ3N0cicgYXQgcG9zaXRpb24gMTAwIGluIHRoZSBkb2N1bWVudFxyXG4vL1xyXG4vLyBDb21wb25lbnRzIGluIGFuIG9wZXJhdGlvbiBhcmUgZXhlY3V0ZWQgc2VxdWVudGlhbGx5LCBzbyB0aGUgcG9zaXRpb24gb2YgY29tcG9uZW50c1xyXG4vLyBhc3N1bWVzIHByZXZpb3VzIGNvbXBvbmVudHMgaGF2ZSBhbHJlYWR5IGV4ZWN1dGVkLlxyXG4vL1xyXG4vLyBFZzogVGhpcyBvcDpcclxuLy8gICBbe2k6J2FiYycsIHA6MH1dXHJcbi8vIGlzIGVxdWl2YWxlbnQgdG8gdGhpcyBvcDpcclxuLy8gICBbe2k6J2EnLCBwOjB9LCB7aTonYicsIHA6MX0sIHtpOidjJywgcDoyfV1cclxuXHJcbi8vIE5PVEU6IFRoZSBnbG9iYWwgc2NvcGUgaGVyZSBpcyBzaGFyZWQgd2l0aCBvdGhlciBzaGFyZWpzIGZpbGVzIHdoZW4gYnVpbHQgd2l0aCBjbG9zdXJlLlxyXG4vLyBCZSBjYXJlZnVsIHdoYXQgZW5kcyB1cCBpbiB5b3VyIG5hbWVzcGFjZS5cclxuXHJcbnZhciB0ZXh0ID0gbW9kdWxlLmV4cG9ydHMgPSB7XHJcbiAgbmFtZTogJ3RleHQwJyxcclxuICB1cmk6ICdodHRwOi8vc2hhcmVqcy5vcmcvdHlwZXMvdGV4dHYwJyxcclxuICBjcmVhdGU6IGZ1bmN0aW9uKGluaXRpYWwpIHtcclxuICAgIGlmICgoaW5pdGlhbCAhPSBudWxsKSAmJiB0eXBlb2YgaW5pdGlhbCAhPT0gJ3N0cmluZycpIHtcclxuICAgICAgdGhyb3cgbmV3IEVycm9yKCdJbml0aWFsIGRhdGEgbXVzdCBiZSBhIHN0cmluZycpO1xyXG4gICAgfVxyXG4gICAgcmV0dXJuIGluaXRpYWwgfHwgJyc7XHJcbiAgfVxyXG59O1xyXG5cclxuLyoqIEluc2VydCBzMiBpbnRvIHMxIGF0IHBvcy4gKi9cclxudmFyIHN0ckluamVjdCA9IGZ1bmN0aW9uKHMxLCBwb3MsIHMyKSB7XHJcbiAgcmV0dXJuIHMxLnNsaWNlKDAsIHBvcykgKyBzMiArIHMxLnNsaWNlKHBvcyk7XHJcbn07XHJcblxyXG4vKiogQ2hlY2sgdGhhdCBhbiBvcGVyYXRpb24gY29tcG9uZW50IGlzIHZhbGlkLiBUaHJvd3MgaWYgaXRzIGludmFsaWQuICovXHJcbnZhciBjaGVja1ZhbGlkQ29tcG9uZW50ID0gZnVuY3Rpb24oYykge1xyXG4gIGlmICh0eXBlb2YgYy5wICE9PSAnbnVtYmVyJylcclxuICAgIHRocm93IG5ldyBFcnJvcignY29tcG9uZW50IG1pc3NpbmcgcG9zaXRpb24gZmllbGQnKTtcclxuXHJcbiAgaWYgKCh0eXBlb2YgYy5pID09PSAnc3RyaW5nJykgPT09ICh0eXBlb2YgYy5kID09PSAnc3RyaW5nJykpXHJcbiAgICB0aHJvdyBuZXcgRXJyb3IoJ2NvbXBvbmVudCBuZWVkcyBhbiBpIG9yIGQgZmllbGQnKTtcclxuXHJcbiAgaWYgKGMucCA8IDApXHJcbiAgICB0aHJvdyBuZXcgRXJyb3IoJ3Bvc2l0aW9uIGNhbm5vdCBiZSBuZWdhdGl2ZScpO1xyXG59O1xyXG5cclxuLyoqIENoZWNrIHRoYXQgYW4gb3BlcmF0aW9uIGlzIHZhbGlkICovXHJcbnZhciBjaGVja1ZhbGlkT3AgPSBmdW5jdGlvbihvcCkge1xyXG4gIGZvciAodmFyIGkgPSAwOyBpIDwgb3AubGVuZ3RoOyBpKyspIHtcclxuICAgIGNoZWNrVmFsaWRDb21wb25lbnQob3BbaV0pO1xyXG4gIH1cclxufTtcclxuXHJcbi8qKiBBcHBseSBvcCB0byBzbmFwc2hvdCAqL1xyXG50ZXh0LmFwcGx5ID0gZnVuY3Rpb24oc25hcHNob3QsIG9wKSB7XHJcbiAgdmFyIGRlbGV0ZWQ7XHJcblxyXG4gIGNoZWNrVmFsaWRPcChvcCk7XHJcbiAgZm9yICh2YXIgaSA9IDA7IGkgPCBvcC5sZW5ndGg7IGkrKykge1xyXG4gICAgdmFyIGNvbXBvbmVudCA9IG9wW2ldO1xyXG4gICAgaWYgKGNvbXBvbmVudC5pICE9IG51bGwpIHtcclxuICAgICAgc25hcHNob3QgPSBzdHJJbmplY3Qoc25hcHNob3QsIGNvbXBvbmVudC5wLCBjb21wb25lbnQuaSk7XHJcbiAgICB9IGVsc2Uge1xyXG4gICAgICBkZWxldGVkID0gc25hcHNob3Quc2xpY2UoY29tcG9uZW50LnAsIGNvbXBvbmVudC5wICsgY29tcG9uZW50LmQubGVuZ3RoKTtcclxuICAgICAgaWYgKGNvbXBvbmVudC5kICE9PSBkZWxldGVkKVxyXG4gICAgICAgIHRocm93IG5ldyBFcnJvcihcIkRlbGV0ZSBjb21wb25lbnQgJ1wiICsgY29tcG9uZW50LmQgKyBcIicgZG9lcyBub3QgbWF0Y2ggZGVsZXRlZCB0ZXh0ICdcIiArIGRlbGV0ZWQgKyBcIidcIik7XHJcblxyXG4gICAgICBzbmFwc2hvdCA9IHNuYXBzaG90LnNsaWNlKDAsIGNvbXBvbmVudC5wKSArIHNuYXBzaG90LnNsaWNlKGNvbXBvbmVudC5wICsgY29tcG9uZW50LmQubGVuZ3RoKTtcclxuICAgIH1cclxuICB9XHJcbiAgcmV0dXJuIHNuYXBzaG90O1xyXG59O1xyXG5cclxuLyoqXHJcbiAqIEFwcGVuZCBhIGNvbXBvbmVudCB0byB0aGUgZW5kIG9mIG5ld09wLiBFeHBvcnRlZCBmb3IgdXNlIGJ5IHRoZSByYW5kb20gb3BcclxuICogZ2VuZXJhdG9yIGFuZCB0aGUgSlNPTjAgdHlwZS5cclxuICovXHJcbnZhciBhcHBlbmQgPSB0ZXh0Ll9hcHBlbmQgPSBmdW5jdGlvbihuZXdPcCwgYykge1xyXG4gIGlmIChjLmkgPT09ICcnIHx8IGMuZCA9PT0gJycpIHJldHVybjtcclxuXHJcbiAgaWYgKG5ld09wLmxlbmd0aCA9PT0gMCkge1xyXG4gICAgbmV3T3AucHVzaChjKTtcclxuICB9IGVsc2Uge1xyXG4gICAgdmFyIGxhc3QgPSBuZXdPcFtuZXdPcC5sZW5ndGggLSAxXTtcclxuXHJcbiAgICBpZiAobGFzdC5pICE9IG51bGwgJiYgYy5pICE9IG51bGwgJiYgbGFzdC5wIDw9IGMucCAmJiBjLnAgPD0gbGFzdC5wICsgbGFzdC5pLmxlbmd0aCkge1xyXG4gICAgICAvLyBDb21wb3NlIHRoZSBpbnNlcnQgaW50byB0aGUgcHJldmlvdXMgaW5zZXJ0XHJcbiAgICAgIG5ld09wW25ld09wLmxlbmd0aCAtIDFdID0ge2k6c3RySW5qZWN0KGxhc3QuaSwgYy5wIC0gbGFzdC5wLCBjLmkpLCBwOmxhc3QucH07XHJcblxyXG4gICAgfSBlbHNlIGlmIChsYXN0LmQgIT0gbnVsbCAmJiBjLmQgIT0gbnVsbCAmJiBjLnAgPD0gbGFzdC5wICYmIGxhc3QucCA8PSBjLnAgKyBjLmQubGVuZ3RoKSB7XHJcbiAgICAgIC8vIENvbXBvc2UgdGhlIGRlbGV0ZXMgdG9nZXRoZXJcclxuICAgICAgbmV3T3BbbmV3T3AubGVuZ3RoIC0gMV0gPSB7ZDpzdHJJbmplY3QoYy5kLCBsYXN0LnAgLSBjLnAsIGxhc3QuZCksIHA6Yy5wfTtcclxuXHJcbiAgICB9IGVsc2Uge1xyXG4gICAgICBuZXdPcC5wdXNoKGMpO1xyXG4gICAgfVxyXG4gIH1cclxufTtcclxuXHJcbi8qKiBDb21wb3NlIG9wMSBhbmQgb3AyIHRvZ2V0aGVyICovXHJcbnRleHQuY29tcG9zZSA9IGZ1bmN0aW9uKG9wMSwgb3AyKSB7XHJcbiAgY2hlY2tWYWxpZE9wKG9wMSk7XHJcbiAgY2hlY2tWYWxpZE9wKG9wMik7XHJcbiAgdmFyIG5ld09wID0gb3AxLnNsaWNlKCk7XHJcbiAgZm9yICh2YXIgaSA9IDA7IGkgPCBvcDIubGVuZ3RoOyBpKyspIHtcclxuICAgIGFwcGVuZChuZXdPcCwgb3AyW2ldKTtcclxuICB9XHJcbiAgcmV0dXJuIG5ld09wO1xyXG59O1xyXG5cclxuLyoqIENsZWFuIHVwIGFuIG9wICovXHJcbnRleHQubm9ybWFsaXplID0gZnVuY3Rpb24ob3ApIHtcclxuICB2YXIgbmV3T3AgPSBbXTtcclxuXHJcbiAgLy8gTm9ybWFsaXplIHNob3VsZCBhbGxvdyBvcHMgd2hpY2ggYXJlIGEgc2luZ2xlICh1bndyYXBwZWQpIGNvbXBvbmVudDpcclxuICAvLyB7aTonYXNkZicsIHA6MjN9LlxyXG4gIC8vIFRoZXJlJ3Mgbm8gZ29vZCB3YXkgdG8gdGVzdCBpZiBzb21ldGhpbmcgaXMgYW4gYXJyYXk6XHJcbiAgLy8gaHR0cDovL3BlcmZlY3Rpb25raWxscy5jb20vaW5zdGFuY2VvZi1jb25zaWRlcmVkLWhhcm1mdWwtb3ItaG93LXRvLXdyaXRlLWEtcm9idXN0LWlzYXJyYXkvXHJcbiAgLy8gc28gdGhpcyBpcyBwcm9iYWJseSB0aGUgbGVhc3QgYmFkIHNvbHV0aW9uLlxyXG4gIGlmIChvcC5pICE9IG51bGwgfHwgb3AucCAhPSBudWxsKSBvcCA9IFtvcF07XHJcblxyXG4gIGZvciAodmFyIGkgPSAwOyBpIDwgb3AubGVuZ3RoOyBpKyspIHtcclxuICAgIHZhciBjID0gb3BbaV07XHJcbiAgICBpZiAoYy5wID09IG51bGwpIGMucCA9IDA7XHJcblxyXG4gICAgYXBwZW5kKG5ld09wLCBjKTtcclxuICB9XHJcblxyXG4gIHJldHVybiBuZXdPcDtcclxufTtcclxuXHJcbi8vIFRoaXMgaGVscGVyIG1ldGhvZCB0cmFuc2Zvcm1zIGEgcG9zaXRpb24gYnkgYW4gb3AgY29tcG9uZW50LlxyXG4vL1xyXG4vLyBJZiBjIGlzIGFuIGluc2VydCwgaW5zZXJ0QWZ0ZXIgc3BlY2lmaWVzIHdoZXRoZXIgdGhlIHRyYW5zZm9ybVxyXG4vLyBpcyBwdXNoZWQgYWZ0ZXIgdGhlIGluc2VydCAodHJ1ZSkgb3IgYmVmb3JlIGl0IChmYWxzZSkuXHJcbi8vXHJcbi8vIGluc2VydEFmdGVyIGlzIG9wdGlvbmFsIGZvciBkZWxldGVzLlxyXG52YXIgdHJhbnNmb3JtUG9zaXRpb24gPSBmdW5jdGlvbihwb3MsIGMsIGluc2VydEFmdGVyKSB7XHJcbiAgLy8gVGhpcyB3aWxsIGdldCBjb2xsYXBzZWQgaW50byBhIGdpYW50IHRlcm5hcnkgYnkgdWdsaWZ5LlxyXG4gIGlmIChjLmkgIT0gbnVsbCkge1xyXG4gICAgaWYgKGMucCA8IHBvcyB8fCAoYy5wID09PSBwb3MgJiYgaW5zZXJ0QWZ0ZXIpKSB7XHJcbiAgICAgIHJldHVybiBwb3MgKyBjLmkubGVuZ3RoO1xyXG4gICAgfSBlbHNlIHtcclxuICAgICAgcmV0dXJuIHBvcztcclxuICAgIH1cclxuICB9IGVsc2Uge1xyXG4gICAgLy8gSSB0aGluayB0aGlzIGNvdWxkIGFsc28gYmUgd3JpdHRlbiBhczogTWF0aC5taW4oYy5wLCBNYXRoLm1pbihjLnAgLVxyXG4gICAgLy8gb3RoZXJDLnAsIG90aGVyQy5kLmxlbmd0aCkpIGJ1dCBJIHRoaW5rIGl0cyBoYXJkZXIgdG8gcmVhZCB0aGF0IHdheSwgYW5kXHJcbiAgICAvLyBpdCBjb21waWxlcyB1c2luZyB0ZXJuYXJ5IG9wZXJhdG9ycyBhbnl3YXkgc28gaXRzIG5vIHNsb3dlciB3cml0dGVuIGxpa2VcclxuICAgIC8vIHRoaXMuXHJcbiAgICBpZiAocG9zIDw9IGMucCkge1xyXG4gICAgICByZXR1cm4gcG9zO1xyXG4gICAgfSBlbHNlIGlmIChwb3MgPD0gYy5wICsgYy5kLmxlbmd0aCkge1xyXG4gICAgICByZXR1cm4gYy5wO1xyXG4gICAgfSBlbHNlIHtcclxuICAgICAgcmV0dXJuIHBvcyAtIGMuZC5sZW5ndGg7XHJcbiAgICB9XHJcbiAgfVxyXG59O1xyXG5cclxuLy8gSGVscGVyIG1ldGhvZCB0byB0cmFuc2Zvcm0gYSBjdXJzb3IgcG9zaXRpb24gYXMgYSByZXN1bHQgb2YgYW4gb3AuXHJcbi8vXHJcbi8vIExpa2UgdHJhbnNmb3JtUG9zaXRpb24gYWJvdmUsIGlmIGMgaXMgYW4gaW5zZXJ0LCBpbnNlcnRBZnRlciBzcGVjaWZpZXNcclxuLy8gd2hldGhlciB0aGUgY3Vyc29yIHBvc2l0aW9uIGlzIHB1c2hlZCBhZnRlciBhbiBpbnNlcnQgKHRydWUpIG9yIGJlZm9yZSBpdFxyXG4vLyAoZmFsc2UpLlxyXG50ZXh0LnRyYW5zZm9ybUN1cnNvciA9IGZ1bmN0aW9uKHBvc2l0aW9uLCBvcCwgc2lkZSkge1xyXG4gIHZhciBpbnNlcnRBZnRlciA9IHNpZGUgPT09ICdyaWdodCc7XHJcbiAgZm9yICh2YXIgaSA9IDA7IGkgPCBvcC5sZW5ndGg7IGkrKykge1xyXG4gICAgcG9zaXRpb24gPSB0cmFuc2Zvcm1Qb3NpdGlvbihwb3NpdGlvbiwgb3BbaV0sIGluc2VydEFmdGVyKTtcclxuICB9XHJcblxyXG4gIHJldHVybiBwb3NpdGlvbjtcclxufTtcclxuXHJcbi8vIFRyYW5zZm9ybSBhbiBvcCBjb21wb25lbnQgYnkgYW5vdGhlciBvcCBjb21wb25lbnQuIEFzeW1tZXRyaWMuXHJcbi8vIFRoZSByZXN1bHQgd2lsbCBiZSBhcHBlbmRlZCB0byBkZXN0aW5hdGlvbi5cclxuLy9cclxuLy8gZXhwb3J0ZWQgZm9yIHVzZSBpbiBKU09OIHR5cGVcclxudmFyIHRyYW5zZm9ybUNvbXBvbmVudCA9IHRleHQuX3RjID0gZnVuY3Rpb24oZGVzdCwgYywgb3RoZXJDLCBzaWRlKSB7XHJcbiAgLy92YXIgY0ludGVyc2VjdCwgaW50ZXJzZWN0RW5kLCBpbnRlcnNlY3RTdGFydCwgbmV3Qywgb3RoZXJJbnRlcnNlY3QsIHM7XHJcblxyXG4gIGNoZWNrVmFsaWRDb21wb25lbnQoYyk7XHJcbiAgY2hlY2tWYWxpZENvbXBvbmVudChvdGhlckMpO1xyXG5cclxuICBpZiAoYy5pICE9IG51bGwpIHtcclxuICAgIC8vIEluc2VydC5cclxuICAgIGFwcGVuZChkZXN0LCB7aTpjLmksIHA6dHJhbnNmb3JtUG9zaXRpb24oYy5wLCBvdGhlckMsIHNpZGUgPT09ICdyaWdodCcpfSk7XHJcbiAgfSBlbHNlIHtcclxuICAgIC8vIERlbGV0ZVxyXG4gICAgaWYgKG90aGVyQy5pICE9IG51bGwpIHtcclxuICAgICAgLy8gRGVsZXRlIHZzIGluc2VydFxyXG4gICAgICB2YXIgcyA9IGMuZDtcclxuICAgICAgaWYgKGMucCA8IG90aGVyQy5wKSB7XHJcbiAgICAgICAgYXBwZW5kKGRlc3QsIHtkOnMuc2xpY2UoMCwgb3RoZXJDLnAgLSBjLnApLCBwOmMucH0pO1xyXG4gICAgICAgIHMgPSBzLnNsaWNlKG90aGVyQy5wIC0gYy5wKTtcclxuICAgICAgfVxyXG4gICAgICBpZiAocyAhPT0gJycpXHJcbiAgICAgICAgYXBwZW5kKGRlc3QsIHtkOiBzLCBwOiBjLnAgKyBvdGhlckMuaS5sZW5ndGh9KTtcclxuXHJcbiAgICB9IGVsc2Uge1xyXG4gICAgICAvLyBEZWxldGUgdnMgZGVsZXRlXHJcbiAgICAgIGlmIChjLnAgPj0gb3RoZXJDLnAgKyBvdGhlckMuZC5sZW5ndGgpXHJcbiAgICAgICAgYXBwZW5kKGRlc3QsIHtkOiBjLmQsIHA6IGMucCAtIG90aGVyQy5kLmxlbmd0aH0pO1xyXG4gICAgICBlbHNlIGlmIChjLnAgKyBjLmQubGVuZ3RoIDw9IG90aGVyQy5wKVxyXG4gICAgICAgIGFwcGVuZChkZXN0LCBjKTtcclxuICAgICAgZWxzZSB7XHJcbiAgICAgICAgLy8gVGhleSBvdmVybGFwIHNvbWV3aGVyZS5cclxuICAgICAgICB2YXIgbmV3QyA9IHtkOiAnJywgcDogYy5wfTtcclxuXHJcbiAgICAgICAgaWYgKGMucCA8IG90aGVyQy5wKVxyXG4gICAgICAgICAgbmV3Qy5kID0gYy5kLnNsaWNlKDAsIG90aGVyQy5wIC0gYy5wKTtcclxuXHJcbiAgICAgICAgaWYgKGMucCArIGMuZC5sZW5ndGggPiBvdGhlckMucCArIG90aGVyQy5kLmxlbmd0aClcclxuICAgICAgICAgIG5ld0MuZCArPSBjLmQuc2xpY2Uob3RoZXJDLnAgKyBvdGhlckMuZC5sZW5ndGggLSBjLnApO1xyXG5cclxuICAgICAgICAvLyBUaGlzIGlzIGVudGlyZWx5IG9wdGlvbmFsIC0gSSdtIGp1c3QgY2hlY2tpbmcgdGhlIGRlbGV0ZWQgdGV4dCBpblxyXG4gICAgICAgIC8vIHRoZSB0d28gb3BzIG1hdGNoZXNcclxuICAgICAgICB2YXIgaW50ZXJzZWN0U3RhcnQgPSBNYXRoLm1heChjLnAsIG90aGVyQy5wKTtcclxuICAgICAgICB2YXIgaW50ZXJzZWN0RW5kID0gTWF0aC5taW4oYy5wICsgYy5kLmxlbmd0aCwgb3RoZXJDLnAgKyBvdGhlckMuZC5sZW5ndGgpO1xyXG4gICAgICAgIHZhciBjSW50ZXJzZWN0ID0gYy5kLnNsaWNlKGludGVyc2VjdFN0YXJ0IC0gYy5wLCBpbnRlcnNlY3RFbmQgLSBjLnApO1xyXG4gICAgICAgIHZhciBvdGhlckludGVyc2VjdCA9IG90aGVyQy5kLnNsaWNlKGludGVyc2VjdFN0YXJ0IC0gb3RoZXJDLnAsIGludGVyc2VjdEVuZCAtIG90aGVyQy5wKTtcclxuICAgICAgICBpZiAoY0ludGVyc2VjdCAhPT0gb3RoZXJJbnRlcnNlY3QpXHJcbiAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoJ0RlbGV0ZSBvcHMgZGVsZXRlIGRpZmZlcmVudCB0ZXh0IGluIHRoZSBzYW1lIHJlZ2lvbiBvZiB0aGUgZG9jdW1lbnQnKTtcclxuXHJcbiAgICAgICAgaWYgKG5ld0MuZCAhPT0gJycpIHtcclxuICAgICAgICAgIG5ld0MucCA9IHRyYW5zZm9ybVBvc2l0aW9uKG5ld0MucCwgb3RoZXJDKTtcclxuICAgICAgICAgIGFwcGVuZChkZXN0LCBuZXdDKTtcclxuICAgICAgICB9XHJcbiAgICAgIH1cclxuICAgIH1cclxuICB9XHJcblxyXG4gIHJldHVybiBkZXN0O1xyXG59O1xyXG5cclxudmFyIGludmVydENvbXBvbmVudCA9IGZ1bmN0aW9uKGMpIHtcclxuICByZXR1cm4gKGMuaSAhPSBudWxsKSA/IHtkOmMuaSwgcDpjLnB9IDoge2k6Yy5kLCBwOmMucH07XHJcbn07XHJcblxyXG4vLyBObyBuZWVkIHRvIHVzZSBhcHBlbmQgZm9yIGludmVydCwgYmVjYXVzZSB0aGUgY29tcG9uZW50cyB3b24ndCBiZSBhYmxlIHRvXHJcbi8vIGNhbmNlbCBvbmUgYW5vdGhlci5cclxudGV4dC5pbnZlcnQgPSBmdW5jdGlvbihvcCkge1xyXG4gIC8vIFNoYWxsb3cgY29weSAmIHJldmVyc2UgdGhhdCBzdWNrYS5cclxuICBvcCA9IG9wLnNsaWNlKCkucmV2ZXJzZSgpO1xyXG4gIGZvciAodmFyIGkgPSAwOyBpIDwgb3AubGVuZ3RoOyBpKyspIHtcclxuICAgIG9wW2ldID0gaW52ZXJ0Q29tcG9uZW50KG9wW2ldKTtcclxuICB9XHJcbiAgcmV0dXJuIG9wO1xyXG59O1xyXG5cclxuZXhwb3J0cy5fYm9vdHN0cmFwVHJhbnNmb3JtKHRleHQsIHRyYW5zZm9ybUNvbXBvbmVudCwgY2hlY2tWYWxpZE9wLCBhcHBlbmQpO1xyXG5cclxuLypcclxuIFRoaXMgaXMgdGhlIGltcGxlbWVudGF0aW9uIG9mIHRoZSBKU09OIE9UIHR5cGUuXHJcblxyXG4gU3BlYyBpcyBoZXJlOiBodHRwczovL2dpdGh1Yi5jb20vam9zZXBoZy9TaGFyZUpTL3dpa2kvSlNPTi1PcGVyYXRpb25zXHJcblxyXG4gTm90ZTogVGhpcyBpcyBiZWluZyBtYWRlIG9ic29sZXRlLiBJdCB3aWxsIHNvb24gYmUgcmVwbGFjZWQgYnkgdGhlIEpTT04yIHR5cGUuXHJcbiovXHJcblxyXG4vKipcclxuICogVVRJTElUWSBGVU5DVElPTlNcclxuICovXHJcblxyXG4vKipcclxuICogQ2hlY2tzIGlmIHRoZSBwYXNzZWQgb2JqZWN0IGlzIGFuIEFycmF5IGluc3RhbmNlLiBDYW4ndCB1c2UgQXJyYXkuaXNBcnJheVxyXG4gKiB5ZXQgYmVjYXVzZSBpdHMgbm90IHN1cHBvcnRlZCBvbiBJRTguXHJcbiAqXHJcbiAqIEBwYXJhbSBvYmpcclxuICogQHJldHVybnMge2Jvb2xlYW59XHJcbiAqL1xyXG52YXIgaXNBcnJheSA9IGZ1bmN0aW9uKG9iaikge1xyXG4gIHJldHVybiBPYmplY3QucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwob2JqKSA9PSAnW29iamVjdCBBcnJheV0nO1xyXG59O1xyXG5cclxuLyoqXHJcbiAqIENsb25lcyB0aGUgcGFzc2VkIG9iamVjdCB1c2luZyBKU09OIHNlcmlhbGl6YXRpb24gKHdoaWNoIGlzIHNsb3cpLlxyXG4gKlxyXG4gKiBoYXgsIGNvcGllZCBmcm9tIHRlc3QvdHlwZXMvanNvbi4gQXBwYXJlbnRseSB0aGlzIGlzIHN0aWxsIHRoZSBmYXN0ZXN0IHdheVxyXG4gKiB0byBkZWVwIGNsb25lIGFuIG9iamVjdCwgYXNzdW1pbmcgd2UgaGF2ZSBicm93c2VyIHN1cHBvcnQgZm9yIEpTT04uICBAc2VlXHJcbiAqIGh0dHA6Ly9qc3BlcmYuY29tL2Nsb25pbmctYW4tb2JqZWN0LzEyXHJcbiAqL1xyXG52YXIgY2xvbmUgPSBmdW5jdGlvbihvKSB7XHJcbiAgcmV0dXJuIEpTT04ucGFyc2UoSlNPTi5zdHJpbmdpZnkobykpO1xyXG59O1xyXG5cclxuLyoqXHJcbiAqIFJlZmVyZW5jZSB0byB0aGUgVGV4dCBPVCB0eXBlLiBUaGlzIGlzIHVzZWQgZm9yIHRoZSBKU09OIFN0cmluZyBvcGVyYXRpb25zLlxyXG4gKiBAdHlwZSB7Kn1cclxuICovXHJcbmlmICh0eXBlb2YgdGV4dCA9PT0gJ3VuZGVmaW5lZCcpXHJcbiAgdmFyIHRleHQgPSB3aW5kb3cub3R0eXBlcy50ZXh0O1xyXG5cclxuLyoqXHJcbiAqIEpTT04gT1QgVHlwZVxyXG4gKiBAdHlwZSB7Kn1cclxuICovXHJcbnZhciBqc29uID0geyBcclxuICBuYW1lOiAnanNvbjAnLFxyXG4gIHVyaTogJ2h0dHA6Ly9zaGFyZWpzLm9yZy90eXBlcy9KU09OdjAnXHJcbn07XHJcblxyXG5qc29uLmNyZWF0ZSA9IGZ1bmN0aW9uKGRhdGEpIHtcclxuICAvLyBOdWxsIGluc3RlYWQgb2YgdW5kZWZpbmVkIGlmIHlvdSBkb24ndCBwYXNzIGFuIGFyZ3VtZW50LlxyXG4gIHJldHVybiBkYXRhID09PSB1bmRlZmluZWQgPyBudWxsIDogZGF0YTtcclxufTtcclxuXHJcbmpzb24uaW52ZXJ0Q29tcG9uZW50ID0gZnVuY3Rpb24oYykge1xyXG4gIHZhciBjXyA9IHtwOiBjLnB9O1xyXG5cclxuICBpZiAoYy5zaSAhPT0gdm9pZCAwKSBjXy5zZCA9IGMuc2k7XHJcbiAgaWYgKGMuc2QgIT09IHZvaWQgMCkgY18uc2kgPSBjLnNkO1xyXG4gIGlmIChjLm9pICE9PSB2b2lkIDApIGNfLm9kID0gYy5vaTtcclxuICBpZiAoYy5vZCAhPT0gdm9pZCAwKSBjXy5vaSA9IGMub2Q7XHJcbiAgaWYgKGMubGkgIT09IHZvaWQgMCkgY18ubGQgPSBjLmxpO1xyXG4gIGlmIChjLmxkICE9PSB2b2lkIDApIGNfLmxpID0gYy5sZDtcclxuICBpZiAoYy5uYSAhPT0gdm9pZCAwKSBjXy5uYSA9IC1jLm5hO1xyXG5cclxuICBpZiAoYy5sbSAhPT0gdm9pZCAwKSB7XHJcbiAgICBjXy5sbSA9IGMucFtjLnAubGVuZ3RoLTFdO1xyXG4gICAgY18ucCA9IGMucC5zbGljZSgwLGMucC5sZW5ndGgtMSkuY29uY2F0KFtjLmxtXSk7XHJcbiAgfVxyXG5cclxuICByZXR1cm4gY187XHJcbn07XHJcblxyXG5qc29uLmludmVydCA9IGZ1bmN0aW9uKG9wKSB7XHJcbiAgdmFyIG9wXyA9IG9wLnNsaWNlKCkucmV2ZXJzZSgpO1xyXG4gIHZhciBpb3AgPSBbXTtcclxuICBmb3IgKHZhciBpID0gMDsgaSA8IG9wXy5sZW5ndGg7IGkrKykge1xyXG4gICAgaW9wLnB1c2goanNvbi5pbnZlcnRDb21wb25lbnQob3BfW2ldKSk7XHJcbiAgfVxyXG4gIHJldHVybiBpb3A7XHJcbn07XHJcblxyXG5qc29uLmNoZWNrVmFsaWRPcCA9IGZ1bmN0aW9uKG9wKSB7XHJcbiAgZm9yICh2YXIgaSA9IDA7IGkgPCBvcC5sZW5ndGg7IGkrKykge1xyXG4gIGlmICghaXNBcnJheShvcFtpXS5wKSlcclxuICAgIHRocm93IG5ldyBFcnJvcignTWlzc2luZyBwYXRoJyk7XHJcbiAgfVxyXG59O1xyXG5cclxuanNvbi5jaGVja0xpc3QgPSBmdW5jdGlvbihlbGVtKSB7XHJcbiAgaWYgKCFpc0FycmF5KGVsZW0pKVxyXG4gICAgdGhyb3cgbmV3IEVycm9yKCdSZWZlcmVuY2VkIGVsZW1lbnQgbm90IGEgbGlzdCcpO1xyXG59O1xyXG5cclxuanNvbi5jaGVja09iaiA9IGZ1bmN0aW9uKGVsZW0pIHtcclxuICBpZiAoZWxlbS5jb25zdHJ1Y3RvciAhPT0gT2JqZWN0KSB7XHJcbiAgICB0aHJvdyBuZXcgRXJyb3IoXCJSZWZlcmVuY2VkIGVsZW1lbnQgbm90IGFuIG9iamVjdCAoaXQgd2FzIFwiICsgSlNPTi5zdHJpbmdpZnkoZWxlbSkgKyBcIilcIik7XHJcbiAgfVxyXG59O1xyXG5cclxuanNvbi5hcHBseSA9IGZ1bmN0aW9uKHNuYXBzaG90LCBvcCkge1xyXG4gIGpzb24uY2hlY2tWYWxpZE9wKG9wKTtcclxuXHJcbiAgb3AgPSBjbG9uZShvcCk7XHJcblxyXG4gIHZhciBjb250YWluZXIgPSB7XHJcbiAgICBkYXRhOiBzbmFwc2hvdFxyXG4gIH07XHJcblxyXG4gIGZvciAodmFyIGkgPSAwOyBpIDwgb3AubGVuZ3RoOyBpKyspIHtcclxuICAgIHZhciBjID0gb3BbaV07XHJcblxyXG4gICAgdmFyIHBhcmVudCA9IG51bGw7XHJcbiAgICB2YXIgcGFyZW50S2V5ID0gbnVsbDtcclxuICAgIHZhciBlbGVtID0gY29udGFpbmVyO1xyXG4gICAgdmFyIGtleSA9ICdkYXRhJztcclxuXHJcbiAgICBmb3IgKHZhciBqID0gMDsgaiA8IGMucC5sZW5ndGg7IGorKykge1xyXG4gICAgICB2YXIgcCA9IGMucFtqXTtcclxuXHJcbiAgICAgIHBhcmVudCA9IGVsZW07XHJcbiAgICAgIHBhcmVudEtleSA9IGtleTtcclxuICAgICAgZWxlbSA9IGVsZW1ba2V5XTtcclxuICAgICAga2V5ID0gcDtcclxuXHJcbiAgICAgIGlmIChwYXJlbnQgPT0gbnVsbClcclxuICAgICAgICB0aHJvdyBuZXcgRXJyb3IoJ1BhdGggaW52YWxpZCcpO1xyXG4gICAgfVxyXG5cclxuICAgIC8vIE51bWJlciBhZGRcclxuICAgIGlmIChjLm5hICE9PSB2b2lkIDApIHtcclxuICAgICAgaWYgKHR5cGVvZiBlbGVtW2tleV0gIT0gJ251bWJlcicpXHJcbiAgICAgICAgdGhyb3cgbmV3IEVycm9yKCdSZWZlcmVuY2VkIGVsZW1lbnQgbm90IGEgbnVtYmVyJyk7XHJcblxyXG4gICAgICBlbGVtW2tleV0gKz0gYy5uYTtcclxuICAgIH1cclxuXHJcbiAgICAvLyBTdHJpbmcgaW5zZXJ0XHJcbiAgICBlbHNlIGlmIChjLnNpICE9PSB2b2lkIDApIHtcclxuICAgICAgaWYgKHR5cGVvZiBlbGVtICE9ICdzdHJpbmcnKVxyXG4gICAgICAgIHRocm93IG5ldyBFcnJvcignUmVmZXJlbmNlZCBlbGVtZW50IG5vdCBhIHN0cmluZyAoaXQgd2FzICcrSlNPTi5zdHJpbmdpZnkoZWxlbSkrJyknKTtcclxuXHJcbiAgICAgIHBhcmVudFtwYXJlbnRLZXldID0gZWxlbS5zbGljZSgwLGtleSkgKyBjLnNpICsgZWxlbS5zbGljZShrZXkpO1xyXG4gICAgfVxyXG5cclxuICAgIC8vIFN0cmluZyBkZWxldGVcclxuICAgIGVsc2UgaWYgKGMuc2QgIT09IHZvaWQgMCkge1xyXG4gICAgICBpZiAodHlwZW9mIGVsZW0gIT0gJ3N0cmluZycpXHJcbiAgICAgICAgdGhyb3cgbmV3IEVycm9yKCdSZWZlcmVuY2VkIGVsZW1lbnQgbm90IGEgc3RyaW5nJyk7XHJcblxyXG4gICAgICBpZiAoZWxlbS5zbGljZShrZXksa2V5ICsgYy5zZC5sZW5ndGgpICE9PSBjLnNkKVxyXG4gICAgICAgIHRocm93IG5ldyBFcnJvcignRGVsZXRlZCBzdHJpbmcgZG9lcyBub3QgbWF0Y2gnKTtcclxuXHJcbiAgICAgIHBhcmVudFtwYXJlbnRLZXldID0gZWxlbS5zbGljZSgwLGtleSkgKyBlbGVtLnNsaWNlKGtleSArIGMuc2QubGVuZ3RoKTtcclxuICAgIH1cclxuXHJcbiAgICAvLyBMaXN0IHJlcGxhY2VcclxuICAgIGVsc2UgaWYgKGMubGkgIT09IHZvaWQgMCAmJiBjLmxkICE9PSB2b2lkIDApIHtcclxuICAgICAganNvbi5jaGVja0xpc3QoZWxlbSk7XHJcbiAgICAgIC8vIFNob3VsZCBjaGVjayB0aGUgbGlzdCBlbGVtZW50IG1hdGNoZXMgYy5sZFxyXG4gICAgICBlbGVtW2tleV0gPSBjLmxpO1xyXG4gICAgfVxyXG5cclxuICAgIC8vIExpc3QgaW5zZXJ0XHJcbiAgICBlbHNlIGlmIChjLmxpICE9PSB2b2lkIDApIHtcclxuICAgICAganNvbi5jaGVja0xpc3QoZWxlbSk7XHJcbiAgICAgIGVsZW0uc3BsaWNlKGtleSwwLCBjLmxpKTtcclxuICAgIH1cclxuXHJcbiAgICAvLyBMaXN0IGRlbGV0ZVxyXG4gICAgZWxzZSBpZiAoYy5sZCAhPT0gdm9pZCAwKSB7XHJcbiAgICAgIGpzb24uY2hlY2tMaXN0KGVsZW0pO1xyXG4gICAgICAvLyBTaG91bGQgY2hlY2sgdGhlIGxpc3QgZWxlbWVudCBtYXRjaGVzIGMubGQgaGVyZSB0b28uXHJcbiAgICAgIGVsZW0uc3BsaWNlKGtleSwxKTtcclxuICAgIH1cclxuXHJcbiAgICAvLyBMaXN0IG1vdmVcclxuICAgIGVsc2UgaWYgKGMubG0gIT09IHZvaWQgMCkge1xyXG4gICAgICBqc29uLmNoZWNrTGlzdChlbGVtKTtcclxuICAgICAgaWYgKGMubG0gIT0ga2V5KSB7XHJcbiAgICAgICAgdmFyIGUgPSBlbGVtW2tleV07XHJcbiAgICAgICAgLy8gUmVtb3ZlIGl0Li4uXHJcbiAgICAgICAgZWxlbS5zcGxpY2Uoa2V5LDEpO1xyXG4gICAgICAgIC8vIEFuZCBpbnNlcnQgaXQgYmFjay5cclxuICAgICAgICBlbGVtLnNwbGljZShjLmxtLDAsZSk7XHJcbiAgICAgIH1cclxuICAgIH1cclxuXHJcbiAgICAvLyBPYmplY3QgaW5zZXJ0IC8gcmVwbGFjZVxyXG4gICAgZWxzZSBpZiAoYy5vaSAhPT0gdm9pZCAwKSB7XHJcbiAgICAgIGpzb24uY2hlY2tPYmooZWxlbSk7XHJcblxyXG4gICAgICAvLyBTaG91bGQgY2hlY2sgdGhhdCBlbGVtW2tleV0gPT0gYy5vZFxyXG4gICAgICBlbGVtW2tleV0gPSBjLm9pO1xyXG4gICAgfVxyXG5cclxuICAgIC8vIE9iamVjdCBkZWxldGVcclxuICAgIGVsc2UgaWYgKGMub2QgIT09IHZvaWQgMCkge1xyXG4gICAgICBqc29uLmNoZWNrT2JqKGVsZW0pO1xyXG5cclxuICAgICAgLy8gU2hvdWxkIGNoZWNrIHRoYXQgZWxlbVtrZXldID09IGMub2RcclxuICAgICAgZGVsZXRlIGVsZW1ba2V5XTtcclxuICAgIH1cclxuXHJcbiAgICBlbHNlIHtcclxuICAgICAgdGhyb3cgbmV3IEVycm9yKCdpbnZhbGlkIC8gbWlzc2luZyBpbnN0cnVjdGlvbiBpbiBvcCcpO1xyXG4gICAgfVxyXG4gIH1cclxuXHJcbiAgcmV0dXJuIGNvbnRhaW5lci5kYXRhO1xyXG59O1xyXG5cclxuLy8gSGVscGVyIGZvciBpbmNyZW1lbnRhbGx5IGFwcGx5aW5nIGFuIG9wZXJhdGlvbiB0byBhIHNuYXBzaG90LiBDYWxscyB5aWVsZFxyXG4vLyBhZnRlciBlYWNoIG9wIGNvbXBvbmVudCBoYXMgYmVlbiBhcHBsaWVkLlxyXG5qc29uLmluY3JlbWVudGFsQXBwbHkgPSBmdW5jdGlvbihzbmFwc2hvdCwgb3AsIF95aWVsZCkge1xyXG4gIGZvciAodmFyIGkgPSAwOyBpIDwgb3AubGVuZ3RoOyBpKyspIHtcclxuICAgIHZhciBzbWFsbE9wID0gW29wW2ldXTtcclxuICAgIHNuYXBzaG90ID0ganNvbi5hcHBseShzbmFwc2hvdCwgc21hbGxPcCk7XHJcbiAgICAvLyBJJ2QganVzdCBjYWxsIHRoaXMgeWllbGQsIGJ1dCB0aGF0cyBhIHJlc2VydmVkIGtleXdvcmQuIEJhaCFcclxuICAgIF95aWVsZChzbWFsbE9wLCBzbmFwc2hvdCk7XHJcbiAgfVxyXG4gIFxyXG4gIHJldHVybiBzbmFwc2hvdDtcclxufTtcclxuXHJcbi8vIENoZWNrcyBpZiB0d28gcGF0aHMsIHAxIGFuZCBwMiBtYXRjaC5cclxudmFyIHBhdGhNYXRjaGVzID0ganNvbi5wYXRoTWF0Y2hlcyA9IGZ1bmN0aW9uKHAxLCBwMiwgaWdub3JlTGFzdCkge1xyXG4gIGlmIChwMS5sZW5ndGggIT0gcDIubGVuZ3RoKVxyXG4gICAgcmV0dXJuIGZhbHNlO1xyXG5cclxuICBmb3IgKHZhciBpID0gMDsgaSA8IHAxLmxlbmd0aDsgaSsrKSB7XHJcbiAgICBpZiAocDFbaV0gIT09IHAyW2ldICYmICghaWdub3JlTGFzdCB8fCBpICE9PSBwMS5sZW5ndGggLSAxKSlcclxuICAgICAgcmV0dXJuIGZhbHNlO1xyXG4gIH1cclxuXHJcbiAgcmV0dXJuIHRydWU7XHJcbn07XHJcblxyXG52YXIgX2NvbnZlcnRUb1RleHRDb21wb25lbnQgPSBmdW5jdGlvbihjb21wb25lbnQpIHtcclxuICB2YXIgbmV3QyA9IHtwOiBjb21wb25lbnQucFtjb21wb25lbnQucC5sZW5ndGggLSAxXX07XHJcbiAgaWYgKGNvbXBvbmVudC5zaSAhPSBudWxsKSB7XHJcbiAgICBuZXdDLmkgPSBjb21wb25lbnQuc2k7XHJcbiAgfSBlbHNlIHtcclxuICAgIG5ld0MuZCA9IGNvbXBvbmVudC5zZDtcclxuICB9XHJcbiAgcmV0dXJuIG5ld0M7XHJcbn07XHJcblxyXG5qc29uLmFwcGVuZCA9IGZ1bmN0aW9uKGRlc3QsYykge1xyXG4gIGMgPSBjbG9uZShjKTtcclxuXHJcbiAgdmFyIGxhc3Q7XHJcblxyXG4gIGlmIChkZXN0Lmxlbmd0aCAhPSAwICYmIHBhdGhNYXRjaGVzKGMucCwgKGxhc3QgPSBkZXN0W2Rlc3QubGVuZ3RoIC0gMV0pLnApKSB7XHJcbiAgICBpZiAobGFzdC5uYSAhPSBudWxsICYmIGMubmEgIT0gbnVsbCkge1xyXG4gICAgICBkZXN0W2Rlc3QubGVuZ3RoIC0gMV0gPSB7cDogbGFzdC5wLCBuYTogbGFzdC5uYSArIGMubmF9O1xyXG4gICAgfSBlbHNlIGlmIChsYXN0LmxpICE9PSB1bmRlZmluZWQgJiYgYy5saSA9PT0gdW5kZWZpbmVkICYmIGMubGQgPT09IGxhc3QubGkpIHtcclxuICAgICAgLy8gaW5zZXJ0IGltbWVkaWF0ZWx5IGZvbGxvd2VkIGJ5IGRlbGV0ZSBiZWNvbWVzIGEgbm9vcC5cclxuICAgICAgaWYgKGxhc3QubGQgIT09IHVuZGVmaW5lZCkge1xyXG4gICAgICAgIC8vIGxlYXZlIHRoZSBkZWxldGUgcGFydCBvZiB0aGUgcmVwbGFjZVxyXG4gICAgICAgIGRlbGV0ZSBsYXN0LmxpO1xyXG4gICAgICB9IGVsc2Uge1xyXG4gICAgICAgIGRlc3QucG9wKCk7XHJcbiAgICAgIH1cclxuICAgIH0gZWxzZSBpZiAobGFzdC5vZCAhPT0gdW5kZWZpbmVkICYmIGxhc3Qub2kgPT09IHVuZGVmaW5lZCAmJiBjLm9pICE9PSB1bmRlZmluZWQgJiYgYy5vZCA9PT0gdW5kZWZpbmVkKSB7XHJcbiAgICAgIGxhc3Qub2kgPSBjLm9pO1xyXG4gICAgfSBlbHNlIGlmIChsYXN0Lm9pICE9PSB1bmRlZmluZWQgJiYgYy5vZCAhPT0gdW5kZWZpbmVkKSB7XHJcbiAgICAgIC8vIFRoZSBsYXN0IHBhdGggY29tcG9uZW50IGluc2VydGVkIHNvbWV0aGluZyB0aGF0IHRoZSBuZXcgY29tcG9uZW50IGRlbGV0ZXMgKG9yIHJlcGxhY2VzKS5cclxuICAgICAgLy8gSnVzdCBtZXJnZSB0aGVtLlxyXG4gICAgICBpZiAoYy5vaSAhPT0gdW5kZWZpbmVkKSB7XHJcbiAgICAgICAgbGFzdC5vaSA9IGMub2k7XHJcbiAgICAgIH0gZWxzZSBpZiAobGFzdC5vZCAhPT0gdW5kZWZpbmVkKSB7XHJcbiAgICAgICAgZGVsZXRlIGxhc3Qub2k7XHJcbiAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgLy8gQW4gaW5zZXJ0IGRpcmVjdGx5IGZvbGxvd2VkIGJ5IGEgZGVsZXRlIHR1cm5zIGludG8gYSBuby1vcCBhbmQgY2FuIGJlIHJlbW92ZWQuXHJcbiAgICAgICAgZGVzdC5wb3AoKTtcclxuICAgICAgfVxyXG4gICAgfSBlbHNlIGlmIChjLmxtICE9PSB1bmRlZmluZWQgJiYgYy5wW2MucC5sZW5ndGggLSAxXSA9PT0gYy5sbSkge1xyXG4gICAgICAvLyBkb24ndCBkbyBhbnl0aGluZ1xyXG4gICAgfSBlbHNlIHtcclxuICAgICAgZGVzdC5wdXNoKGMpO1xyXG4gICAgfVxyXG4gIH0gZWxzZSBpZiAoZGVzdC5sZW5ndGggIT0gMCAmJiBwYXRoTWF0Y2hlcyhjLnAsIGxhc3QucCwgdHJ1ZSkpIHtcclxuICAgIGlmICgoYy5zaSAhPSBudWxsIHx8IGMuc2QgIT0gbnVsbCkgJiYgKGxhc3Quc2kgIT0gbnVsbCB8fCBsYXN0LnNkICE9IG51bGwpKSB7XHJcbiAgICAgIC8vIFRyeSB0byBjb21wb3NlIHRoZSBzdHJpbmcgb3BzIHRvZ2V0aGVyIHVzaW5nIHRleHQncyBlcXVpdmFsZW50IG1ldGhvZHNcclxuICAgICAgdmFyIHRleHRPcCA9IFtfY29udmVydFRvVGV4dENvbXBvbmVudChsYXN0KV07XHJcbiAgICAgIHRleHQuX2FwcGVuZCh0ZXh0T3AsIF9jb252ZXJ0VG9UZXh0Q29tcG9uZW50KGMpKTtcclxuICAgICAgXHJcbiAgICAgIC8vIFRoZW4gY29udmVydCBiYWNrLlxyXG4gICAgICBpZiAodGV4dE9wLmxlbmd0aCAhPT0gMSkge1xyXG4gICAgICAgIGRlc3QucHVzaChjKTtcclxuICAgICAgfSBlbHNlIHtcclxuICAgICAgICB2YXIgdGV4dEMgPSB0ZXh0T3BbMF07XHJcbiAgICAgICAgbGFzdC5wW2xhc3QucC5sZW5ndGggLSAxXSA9IHRleHRDLnA7XHJcbiAgICAgICAgaWYgKHRleHRDLmkgIT0gbnVsbClcclxuICAgICAgICAgIGxhc3Quc2kgPSB0ZXh0Qy5pO1xyXG4gICAgICAgIGVsc2VcclxuICAgICAgICAgIGxhc3Quc2QgPSB0ZXh0Qy5kO1xyXG4gICAgICB9XHJcbiAgICB9IGVsc2Uge1xyXG4gICAgICBkZXN0LnB1c2goYyk7XHJcbiAgICB9XHJcbiAgfSBlbHNlIHtcclxuICAgIGRlc3QucHVzaChjKTtcclxuICB9XHJcbn07XHJcblxyXG5qc29uLmNvbXBvc2UgPSBmdW5jdGlvbihvcDEsb3AyKSB7XHJcbiAganNvbi5jaGVja1ZhbGlkT3Aob3AxKTtcclxuICBqc29uLmNoZWNrVmFsaWRPcChvcDIpO1xyXG5cclxuICB2YXIgbmV3T3AgPSBjbG9uZShvcDEpO1xyXG5cclxuICBmb3IgKHZhciBpID0gMDsgaSA8IG9wMi5sZW5ndGg7IGkrKykge1xyXG4gICAganNvbi5hcHBlbmQobmV3T3Asb3AyW2ldKTtcclxuICB9XHJcblxyXG4gIHJldHVybiBuZXdPcDtcclxufTtcclxuXHJcbmpzb24ubm9ybWFsaXplID0gZnVuY3Rpb24ob3ApIHtcclxuICB2YXIgbmV3T3AgPSBbXTtcclxuXHJcbiAgb3AgPSBpc0FycmF5KG9wKSA/IG9wIDogW29wXTtcclxuXHJcbiAgZm9yICh2YXIgaSA9IDA7IGkgPCBvcC5sZW5ndGg7IGkrKykge1xyXG4gICAgdmFyIGMgPSBvcFtpXTtcclxuICAgIGlmIChjLnAgPT0gbnVsbCkgYy5wID0gW107XHJcblxyXG4gICAganNvbi5hcHBlbmQobmV3T3AsYyk7XHJcbiAgfVxyXG5cclxuICByZXR1cm4gbmV3T3A7XHJcbn07XHJcblxyXG4vLyBSZXR1cm5zIHRydWUgaWYgYW4gb3AgYXQgb3RoZXJQYXRoIG1heSBhZmZlY3QgYW4gb3AgYXQgcGF0aFxyXG5qc29uLmNhbk9wQWZmZWN0T3AgPSBmdW5jdGlvbihvdGhlclBhdGgscGF0aCkge1xyXG4gIGlmIChvdGhlclBhdGgubGVuZ3RoID09PSAwKSByZXR1cm4gdHJ1ZTtcclxuICBpZiAocGF0aC5sZW5ndGggPT09IDApIHJldHVybiBmYWxzZTtcclxuXHJcbiAgcGF0aCA9IHBhdGguc2xpY2UoMCxwYXRoLmxlbmd0aCAtIDEpO1xyXG4gIG90aGVyUGF0aCA9IG90aGVyUGF0aC5zbGljZSgwLG90aGVyUGF0aC5sZW5ndGggLSAxKTtcclxuXHJcbiAgZm9yICh2YXIgaSA9IDA7IGkgPCBvdGhlclBhdGgubGVuZ3RoOyBpKyspIHtcclxuICAgIHZhciBwID0gb3RoZXJQYXRoW2ldO1xyXG4gICAgaWYgKGkgPj0gcGF0aC5sZW5ndGggfHwgcCAhPSBwYXRoW2ldKSByZXR1cm4gZmFsc2U7XHJcbiAgfVxyXG5cclxuICAvLyBTYW1lXHJcbiAgcmV0dXJuIHRydWU7XHJcbn07XHJcblxyXG4vLyB0cmFuc2Zvcm0gYyBzbyBpdCBhcHBsaWVzIHRvIGEgZG9jdW1lbnQgd2l0aCBvdGhlckMgYXBwbGllZC5cclxuanNvbi50cmFuc2Zvcm1Db21wb25lbnQgPSBmdW5jdGlvbihkZXN0LCBjLCBvdGhlckMsIHR5cGUpIHtcclxuICBjID0gY2xvbmUoYyk7XHJcblxyXG4gIGlmIChjLm5hICE9PSB2b2lkIDApXHJcbiAgICBjLnAucHVzaCgwKTtcclxuXHJcbiAgaWYgKG90aGVyQy5uYSAhPT0gdm9pZCAwKVxyXG4gICAgb3RoZXJDLnAucHVzaCgwKTtcclxuXHJcbiAgdmFyIGNvbW1vbjtcclxuICBpZiAoanNvbi5jYW5PcEFmZmVjdE9wKG90aGVyQy5wLCBjLnApKVxyXG4gICAgY29tbW9uID0gb3RoZXJDLnAubGVuZ3RoIC0gMTtcclxuXHJcbiAgdmFyIGNvbW1vbjI7XHJcbiAgaWYgKGpzb24uY2FuT3BBZmZlY3RPcChjLnAsb3RoZXJDLnApKVxyXG4gICAgY29tbW9uMiA9IGMucC5sZW5ndGggLSAxO1xyXG5cclxuICB2YXIgY3BsZW5ndGggPSBjLnAubGVuZ3RoO1xyXG4gIHZhciBvdGhlckNwbGVuZ3RoID0gb3RoZXJDLnAubGVuZ3RoO1xyXG5cclxuICBpZiAoYy5uYSAhPT0gdm9pZCAwKSAvLyBoYXhcclxuICAgIGMucC5wb3AoKTtcclxuXHJcbiAgaWYgKG90aGVyQy5uYSAhPT0gdm9pZCAwKVxyXG4gICAgb3RoZXJDLnAucG9wKCk7XHJcblxyXG4gIGlmIChvdGhlckMubmEpIHtcclxuICAgIGlmIChjb21tb24yICE9IG51bGwgJiYgb3RoZXJDcGxlbmd0aCA+PSBjcGxlbmd0aCAmJiBvdGhlckMucFtjb21tb24yXSA9PSBjLnBbY29tbW9uMl0pIHtcclxuICAgICAgaWYgKGMubGQgIT09IHZvaWQgMCkge1xyXG4gICAgICAgIHZhciBvYyA9IGNsb25lKG90aGVyQyk7XHJcbiAgICAgICAgb2MucCA9IG9jLnAuc2xpY2UoY3BsZW5ndGgpO1xyXG4gICAgICAgIGMubGQgPSBqc29uLmFwcGx5KGNsb25lKGMubGQpLFtvY10pO1xyXG4gICAgICB9IGVsc2UgaWYgKGMub2QgIT09IHZvaWQgMCkge1xyXG4gICAgICAgIHZhciBvYyA9IGNsb25lKG90aGVyQyk7XHJcbiAgICAgICAgb2MucCA9IG9jLnAuc2xpY2UoY3BsZW5ndGgpO1xyXG4gICAgICAgIGMub2QgPSBqc29uLmFwcGx5KGNsb25lKGMub2QpLFtvY10pO1xyXG4gICAgICB9XHJcbiAgICB9XHJcbiAgICBqc29uLmFwcGVuZChkZXN0LGMpO1xyXG4gICAgcmV0dXJuIGRlc3Q7XHJcbiAgfVxyXG5cclxuICAvLyBpZiBjIGlzIGRlbGV0aW5nIHNvbWV0aGluZywgYW5kIHRoYXQgdGhpbmcgaXMgY2hhbmdlZCBieSBvdGhlckMsIHdlIG5lZWQgdG9cclxuICAvLyB1cGRhdGUgYyB0byByZWZsZWN0IHRoYXQgY2hhbmdlIGZvciBpbnZlcnRpYmlsaXR5LlxyXG4gIC8vIFRPRE8gdGhpcyBpcyBwcm9iYWJseSBub3QgbmVlZGVkIHNpbmNlIHdlIGRvbid0IGhhdmUgaW52ZXJ0aWJpbGl0eVxyXG4gIGlmIChjb21tb24yICE9IG51bGwgJiYgb3RoZXJDcGxlbmd0aCA+IGNwbGVuZ3RoICYmIGMucFtjb21tb24yXSA9PSBvdGhlckMucFtjb21tb24yXSkge1xyXG4gICAgaWYgKGMubGQgIT09IHZvaWQgMCkge1xyXG4gICAgICB2YXIgb2MgPSBjbG9uZShvdGhlckMpO1xyXG4gICAgICBvYy5wID0gb2MucC5zbGljZShjcGxlbmd0aCk7XHJcbiAgICAgIGMubGQgPSBqc29uLmFwcGx5KGNsb25lKGMubGQpLFtvY10pO1xyXG4gICAgfSBlbHNlIGlmIChjLm9kICE9PSB2b2lkIDApIHtcclxuICAgICAgdmFyIG9jID0gY2xvbmUob3RoZXJDKTtcclxuICAgICAgb2MucCA9IG9jLnAuc2xpY2UoY3BsZW5ndGgpO1xyXG4gICAgICBjLm9kID0ganNvbi5hcHBseShjbG9uZShjLm9kKSxbb2NdKTtcclxuICAgIH1cclxuICB9XHJcblxyXG4gIGlmIChjb21tb24gIT0gbnVsbCkge1xyXG4gICAgdmFyIGNvbW1vbk9wZXJhbmQgPSBjcGxlbmd0aCA9PSBvdGhlckNwbGVuZ3RoO1xyXG5cclxuICAgIC8vIHRyYW5zZm9ybSBiYXNlZCBvbiBvdGhlckNcclxuICAgIGlmIChvdGhlckMubmEgIT09IHZvaWQgMCkge1xyXG4gICAgICAvLyB0aGlzIGNhc2UgaXMgaGFuZGxlZCBhYm92ZSBkdWUgdG8gaWNreSBwYXRoIGhheFxyXG4gICAgfSBlbHNlIGlmIChvdGhlckMuc2kgIT09IHZvaWQgMCB8fCBvdGhlckMuc2QgIT09IHZvaWQgMCkge1xyXG4gICAgICAvLyBTdHJpbmcgb3AgdnMgc3RyaW5nIG9wIC0gcGFzcyB0aHJvdWdoIHRvIHRleHQgdHlwZVxyXG4gICAgICBpZiAoYy5zaSAhPT0gdm9pZCAwIHx8IGMuc2QgIT09IHZvaWQgMCkge1xyXG4gICAgICAgIGlmICghY29tbW9uT3BlcmFuZCkgdGhyb3cgbmV3IEVycm9yKCdtdXN0IGJlIGEgc3RyaW5nPycpO1xyXG5cclxuICAgICAgICAvLyBDb252ZXJ0IGFuIG9wIGNvbXBvbmVudCB0byBhIHRleHQgb3AgY29tcG9uZW50IHNvIHdlIGNhbiB1c2UgdGhlXHJcbiAgICAgICAgLy8gdGV4dCB0eXBlJ3MgdHJhbnNmb3JtIGZ1bmN0aW9uXHJcbiAgICAgICAgdmFyIHRjMSA9IF9jb252ZXJ0VG9UZXh0Q29tcG9uZW50KGMpO1xyXG4gICAgICAgIHZhciB0YzIgPSBfY29udmVydFRvVGV4dENvbXBvbmVudChvdGhlckMpO1xyXG5cclxuICAgICAgICB2YXIgcmVzID0gW107XHJcblxyXG4gICAgICAgIC8vIGFjdHVhbGx5IHRyYW5zZm9ybVxyXG4gICAgICAgIHRleHQuX3RjKHJlcywgdGMxLCB0YzIsIHR5cGUpO1xyXG4gICAgICAgIFxyXG4gICAgICAgIC8vIC4uLi4gdGhlbiBjb252ZXJ0IHRoZSByZXN1bHQgYmFjayBpbnRvIGEgSlNPTiBvcCBhZ2Fpbi5cclxuICAgICAgICBmb3IgKHZhciBpID0gMDsgaSA8IHJlcy5sZW5ndGg7IGkrKykge1xyXG4gICAgICAgICAgLy8gVGV4dCBjb21wb25lbnRcclxuICAgICAgICAgIHZhciB0YyA9IHJlc1tpXTtcclxuICAgICAgICAgIC8vIEpTT04gY29tcG9uZW50XHJcbiAgICAgICAgICB2YXIgamMgPSB7cDogYy5wLnNsaWNlKDAsIGNvbW1vbil9O1xyXG4gICAgICAgICAgamMucC5wdXNoKHRjLnApO1xyXG5cclxuICAgICAgICAgIGlmICh0Yy5pICE9IG51bGwpIGpjLnNpID0gdGMuaTtcclxuICAgICAgICAgIGlmICh0Yy5kICE9IG51bGwpIGpjLnNkID0gdGMuZDtcclxuICAgICAgICAgIGpzb24uYXBwZW5kKGRlc3QsIGpjKTtcclxuICAgICAgICB9XHJcbiAgICAgICAgcmV0dXJuIGRlc3Q7XHJcbiAgICAgIH1cclxuICAgIH0gZWxzZSBpZiAob3RoZXJDLmxpICE9PSB2b2lkIDAgJiYgb3RoZXJDLmxkICE9PSB2b2lkIDApIHtcclxuICAgICAgaWYgKG90aGVyQy5wW2NvbW1vbl0gPT09IGMucFtjb21tb25dKSB7XHJcbiAgICAgICAgLy8gbm9vcFxyXG5cclxuICAgICAgICBpZiAoIWNvbW1vbk9wZXJhbmQpIHtcclxuICAgICAgICAgIHJldHVybiBkZXN0O1xyXG4gICAgICAgIH0gZWxzZSBpZiAoYy5sZCAhPT0gdm9pZCAwKSB7XHJcbiAgICAgICAgICAvLyB3ZSdyZSB0cnlpbmcgdG8gZGVsZXRlIHRoZSBzYW1lIGVsZW1lbnQsIC0+IG5vb3BcclxuICAgICAgICAgIGlmIChjLmxpICE9PSB2b2lkIDAgJiYgdHlwZSA9PT0gJ2xlZnQnKSB7XHJcbiAgICAgICAgICAgIC8vIHdlJ3JlIGJvdGggcmVwbGFjaW5nIG9uZSBlbGVtZW50IHdpdGggYW5vdGhlci4gb25seSBvbmUgY2FuIHN1cnZpdmVcclxuICAgICAgICAgICAgYy5sZCA9IGNsb25lKG90aGVyQy5saSk7XHJcbiAgICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICByZXR1cm4gZGVzdDtcclxuICAgICAgICAgIH1cclxuICAgICAgICB9XHJcbiAgICAgIH1cclxuICAgIH0gZWxzZSBpZiAob3RoZXJDLmxpICE9PSB2b2lkIDApIHtcclxuICAgICAgaWYgKGMubGkgIT09IHZvaWQgMCAmJiBjLmxkID09PSB1bmRlZmluZWQgJiYgY29tbW9uT3BlcmFuZCAmJiBjLnBbY29tbW9uXSA9PT0gb3RoZXJDLnBbY29tbW9uXSkge1xyXG4gICAgICAgIC8vIGluIGxpIHZzLiBsaSwgbGVmdCB3aW5zLlxyXG4gICAgICAgIGlmICh0eXBlID09PSAncmlnaHQnKVxyXG4gICAgICAgICAgYy5wW2NvbW1vbl0rKztcclxuICAgICAgfSBlbHNlIGlmIChvdGhlckMucFtjb21tb25dIDw9IGMucFtjb21tb25dKSB7XHJcbiAgICAgICAgYy5wW2NvbW1vbl0rKztcclxuICAgICAgfVxyXG5cclxuICAgICAgaWYgKGMubG0gIT09IHZvaWQgMCkge1xyXG4gICAgICAgIGlmIChjb21tb25PcGVyYW5kKSB7XHJcbiAgICAgICAgICAvLyBvdGhlckMgZWRpdHMgdGhlIHNhbWUgbGlzdCB3ZSBlZGl0XHJcbiAgICAgICAgICBpZiAob3RoZXJDLnBbY29tbW9uXSA8PSBjLmxtKVxyXG4gICAgICAgICAgICBjLmxtKys7XHJcbiAgICAgICAgICAvLyBjaGFuZ2luZyBjLmZyb20gaXMgaGFuZGxlZCBhYm92ZS5cclxuICAgICAgICB9XHJcbiAgICAgIH1cclxuICAgIH0gZWxzZSBpZiAob3RoZXJDLmxkICE9PSB2b2lkIDApIHtcclxuICAgICAgaWYgKGMubG0gIT09IHZvaWQgMCkge1xyXG4gICAgICAgIGlmIChjb21tb25PcGVyYW5kKSB7XHJcbiAgICAgICAgICBpZiAob3RoZXJDLnBbY29tbW9uXSA9PT0gYy5wW2NvbW1vbl0pIHtcclxuICAgICAgICAgICAgLy8gdGhleSBkZWxldGVkIHRoZSB0aGluZyB3ZSdyZSB0cnlpbmcgdG8gbW92ZVxyXG4gICAgICAgICAgICByZXR1cm4gZGVzdDtcclxuICAgICAgICAgIH1cclxuICAgICAgICAgIC8vIG90aGVyQyBlZGl0cyB0aGUgc2FtZSBsaXN0IHdlIGVkaXRcclxuICAgICAgICAgIHZhciBwID0gb3RoZXJDLnBbY29tbW9uXTtcclxuICAgICAgICAgIHZhciBmcm9tID0gYy5wW2NvbW1vbl07XHJcbiAgICAgICAgICB2YXIgdG8gPSBjLmxtO1xyXG4gICAgICAgICAgaWYgKHAgPCB0byB8fCAocCA9PT0gdG8gJiYgZnJvbSA8IHRvKSlcclxuICAgICAgICAgICAgYy5sbS0tO1xyXG5cclxuICAgICAgICB9XHJcbiAgICAgIH1cclxuXHJcbiAgICAgIGlmIChvdGhlckMucFtjb21tb25dIDwgYy5wW2NvbW1vbl0pIHtcclxuICAgICAgICBjLnBbY29tbW9uXS0tO1xyXG4gICAgICB9IGVsc2UgaWYgKG90aGVyQy5wW2NvbW1vbl0gPT09IGMucFtjb21tb25dKSB7XHJcbiAgICAgICAgaWYgKG90aGVyQ3BsZW5ndGggPCBjcGxlbmd0aCkge1xyXG4gICAgICAgICAgLy8gd2UncmUgYmVsb3cgdGhlIGRlbGV0ZWQgZWxlbWVudCwgc28gLT4gbm9vcFxyXG4gICAgICAgICAgcmV0dXJuIGRlc3Q7XHJcbiAgICAgICAgfSBlbHNlIGlmIChjLmxkICE9PSB2b2lkIDApIHtcclxuICAgICAgICAgIGlmIChjLmxpICE9PSB2b2lkIDApIHtcclxuICAgICAgICAgICAgLy8gd2UncmUgcmVwbGFjaW5nLCB0aGV5J3JlIGRlbGV0aW5nLiB3ZSBiZWNvbWUgYW4gaW5zZXJ0LlxyXG4gICAgICAgICAgICBkZWxldGUgYy5sZDtcclxuICAgICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICAgIC8vIHdlJ3JlIHRyeWluZyB0byBkZWxldGUgdGhlIHNhbWUgZWxlbWVudCwgLT4gbm9vcFxyXG4gICAgICAgICAgICByZXR1cm4gZGVzdDtcclxuICAgICAgICAgIH1cclxuICAgICAgICB9XHJcbiAgICAgIH1cclxuXHJcbiAgICB9IGVsc2UgaWYgKG90aGVyQy5sbSAhPT0gdm9pZCAwKSB7XHJcbiAgICAgIGlmIChjLmxtICE9PSB2b2lkIDAgJiYgY3BsZW5ndGggPT09IG90aGVyQ3BsZW5ndGgpIHtcclxuICAgICAgICAvLyBsbSB2cyBsbSwgaGVyZSB3ZSBnbyFcclxuICAgICAgICB2YXIgZnJvbSA9IGMucFtjb21tb25dO1xyXG4gICAgICAgIHZhciB0byA9IGMubG07XHJcbiAgICAgICAgdmFyIG90aGVyRnJvbSA9IG90aGVyQy5wW2NvbW1vbl07XHJcbiAgICAgICAgdmFyIG90aGVyVG8gPSBvdGhlckMubG07XHJcbiAgICAgICAgaWYgKG90aGVyRnJvbSAhPT0gb3RoZXJUbykge1xyXG4gICAgICAgICAgLy8gaWYgb3RoZXJGcm9tID09IG90aGVyVG8sIHdlIGRvbid0IG5lZWQgdG8gY2hhbmdlIG91ciBvcC5cclxuXHJcbiAgICAgICAgICAvLyB3aGVyZSBkaWQgbXkgdGhpbmcgZ28/XHJcbiAgICAgICAgICBpZiAoZnJvbSA9PT0gb3RoZXJGcm9tKSB7XHJcbiAgICAgICAgICAgIC8vIHRoZXkgbW92ZWQgaXQhIHRpZSBicmVhay5cclxuICAgICAgICAgICAgaWYgKHR5cGUgPT09ICdsZWZ0Jykge1xyXG4gICAgICAgICAgICAgIGMucFtjb21tb25dID0gb3RoZXJUbztcclxuICAgICAgICAgICAgICBpZiAoZnJvbSA9PT0gdG8pIC8vIHVnaFxyXG4gICAgICAgICAgICAgICAgYy5sbSA9IG90aGVyVG87XHJcbiAgICAgICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICAgICAgcmV0dXJuIGRlc3Q7XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICAgIC8vIHRoZXkgbW92ZWQgYXJvdW5kIGl0XHJcbiAgICAgICAgICAgIGlmIChmcm9tID4gb3RoZXJGcm9tKSBjLnBbY29tbW9uXS0tO1xyXG4gICAgICAgICAgICBpZiAoZnJvbSA+IG90aGVyVG8pIGMucFtjb21tb25dKys7XHJcbiAgICAgICAgICAgIGVsc2UgaWYgKGZyb20gPT09IG90aGVyVG8pIHtcclxuICAgICAgICAgICAgICBpZiAob3RoZXJGcm9tID4gb3RoZXJUbykge1xyXG4gICAgICAgICAgICAgICAgYy5wW2NvbW1vbl0rKztcclxuICAgICAgICAgICAgICAgIGlmIChmcm9tID09PSB0bykgLy8gdWdoLCBhZ2FpblxyXG4gICAgICAgICAgICAgICAgICBjLmxtKys7XHJcbiAgICAgICAgICAgICAgfVxyXG4gICAgICAgICAgICB9XHJcblxyXG4gICAgICAgICAgICAvLyBzdGVwIDI6IHdoZXJlIGFtIGkgZ29pbmcgdG8gcHV0IGl0P1xyXG4gICAgICAgICAgICBpZiAodG8gPiBvdGhlckZyb20pIHtcclxuICAgICAgICAgICAgICBjLmxtLS07XHJcbiAgICAgICAgICAgIH0gZWxzZSBpZiAodG8gPT09IG90aGVyRnJvbSkge1xyXG4gICAgICAgICAgICAgIGlmICh0byA+IGZyb20pXHJcbiAgICAgICAgICAgICAgICBjLmxtLS07XHJcbiAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgaWYgKHRvID4gb3RoZXJUbykge1xyXG4gICAgICAgICAgICAgIGMubG0rKztcclxuICAgICAgICAgICAgfSBlbHNlIGlmICh0byA9PT0gb3RoZXJUbykge1xyXG4gICAgICAgICAgICAgIC8vIGlmIHdlJ3JlIGJvdGggbW92aW5nIGluIHRoZSBzYW1lIGRpcmVjdGlvbiwgdGllIGJyZWFrXHJcbiAgICAgICAgICAgICAgaWYgKChvdGhlclRvID4gb3RoZXJGcm9tICYmIHRvID4gZnJvbSkgfHxcclxuICAgICAgICAgICAgICAgICAgKG90aGVyVG8gPCBvdGhlckZyb20gJiYgdG8gPCBmcm9tKSkge1xyXG4gICAgICAgICAgICAgICAgaWYgKHR5cGUgPT09ICdyaWdodCcpIGMubG0rKztcclxuICAgICAgICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgICAgICAgaWYgKHRvID4gZnJvbSkgYy5sbSsrO1xyXG4gICAgICAgICAgICAgICAgZWxzZSBpZiAodG8gPT09IG90aGVyRnJvbSkgYy5sbS0tO1xyXG4gICAgICAgICAgICAgIH1cclxuICAgICAgICAgICAgfVxyXG4gICAgICAgICAgfVxyXG4gICAgICAgIH1cclxuICAgICAgfSBlbHNlIGlmIChjLmxpICE9PSB2b2lkIDAgJiYgYy5sZCA9PT0gdW5kZWZpbmVkICYmIGNvbW1vbk9wZXJhbmQpIHtcclxuICAgICAgICAvLyBsaVxyXG4gICAgICAgIHZhciBmcm9tID0gb3RoZXJDLnBbY29tbW9uXTtcclxuICAgICAgICB2YXIgdG8gPSBvdGhlckMubG07XHJcbiAgICAgICAgcCA9IGMucFtjb21tb25dO1xyXG4gICAgICAgIGlmIChwID4gZnJvbSkgYy5wW2NvbW1vbl0tLTtcclxuICAgICAgICBpZiAocCA+IHRvKSBjLnBbY29tbW9uXSsrO1xyXG4gICAgICB9IGVsc2Uge1xyXG4gICAgICAgIC8vIGxkLCBsZCtsaSwgc2ksIHNkLCBuYSwgb2ksIG9kLCBvaStvZCwgYW55IGxpIG9uIGFuIGVsZW1lbnQgYmVuZWF0aFxyXG4gICAgICAgIC8vIHRoZSBsbVxyXG4gICAgICAgIC8vXHJcbiAgICAgICAgLy8gaS5lLiB0aGluZ3MgY2FyZSBhYm91dCB3aGVyZSB0aGVpciBpdGVtIGlzIGFmdGVyIHRoZSBtb3ZlLlxyXG4gICAgICAgIHZhciBmcm9tID0gb3RoZXJDLnBbY29tbW9uXTtcclxuICAgICAgICB2YXIgdG8gPSBvdGhlckMubG07XHJcbiAgICAgICAgcCA9IGMucFtjb21tb25dO1xyXG4gICAgICAgIGlmIChwID09PSBmcm9tKSB7XHJcbiAgICAgICAgICBjLnBbY29tbW9uXSA9IHRvO1xyXG4gICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICBpZiAocCA+IGZyb20pIGMucFtjb21tb25dLS07XHJcbiAgICAgICAgICBpZiAocCA+IHRvKSBjLnBbY29tbW9uXSsrO1xyXG4gICAgICAgICAgZWxzZSBpZiAocCA9PT0gdG8gJiYgZnJvbSA+IHRvKSBjLnBbY29tbW9uXSsrO1xyXG4gICAgICAgIH1cclxuICAgICAgfVxyXG4gICAgfVxyXG4gICAgZWxzZSBpZiAob3RoZXJDLm9pICE9PSB2b2lkIDAgJiYgb3RoZXJDLm9kICE9PSB2b2lkIDApIHtcclxuICAgICAgaWYgKGMucFtjb21tb25dID09PSBvdGhlckMucFtjb21tb25dKSB7XHJcbiAgICAgICAgaWYgKGMub2kgIT09IHZvaWQgMCAmJiBjb21tb25PcGVyYW5kKSB7XHJcbiAgICAgICAgICAvLyB3ZSBpbnNlcnRlZCB3aGVyZSBzb21lb25lIGVsc2UgcmVwbGFjZWRcclxuICAgICAgICAgIGlmICh0eXBlID09PSAncmlnaHQnKSB7XHJcbiAgICAgICAgICAgIC8vIGxlZnQgd2luc1xyXG4gICAgICAgICAgICByZXR1cm4gZGVzdDtcclxuICAgICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICAgIC8vIHdlIHdpbiwgbWFrZSBvdXIgb3AgcmVwbGFjZSB3aGF0IHRoZXkgaW5zZXJ0ZWRcclxuICAgICAgICAgICAgYy5vZCA9IG90aGVyQy5vaTtcclxuICAgICAgICAgIH1cclxuICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgLy8gLT4gbm9vcCBpZiB0aGUgb3RoZXIgY29tcG9uZW50IGlzIGRlbGV0aW5nIHRoZSBzYW1lIG9iamVjdCAob3IgYW55IHBhcmVudClcclxuICAgICAgICAgIHJldHVybiBkZXN0O1xyXG4gICAgICAgIH1cclxuICAgICAgfVxyXG4gICAgfSBlbHNlIGlmIChvdGhlckMub2kgIT09IHZvaWQgMCkge1xyXG4gICAgICBpZiAoYy5vaSAhPT0gdm9pZCAwICYmIGMucFtjb21tb25dID09PSBvdGhlckMucFtjb21tb25dKSB7XHJcbiAgICAgICAgLy8gbGVmdCB3aW5zIGlmIHdlIHRyeSB0byBpbnNlcnQgYXQgdGhlIHNhbWUgcGxhY2VcclxuICAgICAgICBpZiAodHlwZSA9PT0gJ2xlZnQnKSB7XHJcbiAgICAgICAgICBqc29uLmFwcGVuZChkZXN0LHtwOiBjLnAsIG9kOm90aGVyQy5vaX0pO1xyXG4gICAgICAgIH0gZWxzZSB7XHJcbiAgICAgICAgICByZXR1cm4gZGVzdDtcclxuICAgICAgICB9XHJcbiAgICAgIH1cclxuICAgIH0gZWxzZSBpZiAob3RoZXJDLm9kICE9PSB2b2lkIDApIHtcclxuICAgICAgaWYgKGMucFtjb21tb25dID09IG90aGVyQy5wW2NvbW1vbl0pIHtcclxuICAgICAgICBpZiAoIWNvbW1vbk9wZXJhbmQpXHJcbiAgICAgICAgICByZXR1cm4gZGVzdDtcclxuICAgICAgICBpZiAoYy5vaSAhPT0gdm9pZCAwKSB7XHJcbiAgICAgICAgICBkZWxldGUgYy5vZDtcclxuICAgICAgICB9IGVsc2Uge1xyXG4gICAgICAgICAgcmV0dXJuIGRlc3Q7XHJcbiAgICAgICAgfVxyXG4gICAgICB9XHJcbiAgICB9XHJcbiAgfVxyXG5cclxuICBqc29uLmFwcGVuZChkZXN0LGMpO1xyXG4gIHJldHVybiBkZXN0O1xyXG59O1xyXG5cclxuZXhwb3J0cy5fYm9vdHN0cmFwVHJhbnNmb3JtKGpzb24sIGpzb24udHJhbnNmb3JtQ29tcG9uZW50LCBqc29uLmNoZWNrVmFsaWRPcCwganNvbi5hcHBlbmQpO1xyXG5cclxuXHJcbm1vZHVsZS5leHBvcnRzID0ganNvbjtcclxuLy8gVGhpcyBpcyBpbmNsdWRlZCBhZnRlciB0aGUgSlMgZm9yIGVhY2ggdHlwZSB3aGVuIHdlIGJ1aWxkIGZvciB0aGUgd2ViLlxyXG5cclxuICB2YXIgX3R5cGVzID0gd2luZG93Lm90dHlwZXMgPSB3aW5kb3cub3R0eXBlcyB8fCB7fTtcclxuICB2YXIgX3QgPSBtb2R1bGUuZXhwb3J0cztcclxuICBfdHlwZXNbX3QubmFtZV0gPSBfdDtcclxuXHJcbiAgaWYgKF90LnVyaSkgX3R5cGVzW190LnVyaV0gPSBfdDtcclxufSkoKTtcclxuIiwibW9kdWxlLmV4cG9ydHMgPSBmdW5jdGlvbiBnZW5pZChsZW4sIHByZWZpeCwga2V5c3BhY2UpIHtcclxuICBpZiAobGVuID09IG51bGwpIHtcclxuICAgIGxlbiA9IDMyO1xyXG4gIH1cclxuICBpZiAocHJlZml4ID09IG51bGwpIHtcclxuICAgIHByZWZpeCA9IFwiXCI7XHJcbiAgfVxyXG4gIGlmIChrZXlzcGFjZSA9PSBudWxsKSB7XHJcbiAgICBrZXlzcGFjZSA9IFwiQUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVphYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5ejAxMjM0NTY3ODlcIjtcclxuICB9XHJcbiAgd2hpbGUgKGxlbi0tID4gMCkge1xyXG4gICAgcHJlZml4ICs9IGtleXNwYWNlLmNoYXJBdChNYXRoLmZsb29yKE1hdGgucmFuZG9tKCkgKiBrZXlzcGFjZS5sZW5ndGgpKTtcclxuICB9XHJcbiAgcmV0dXJuIHByZWZpeDtcclxufTsiLCIvKipcbiAqIEBsaWNlbnNlXG4gKiBMby1EYXNoIDIuMC4wIDxodHRwOi8vbG9kYXNoLmNvbS8+XG4gKiBDb3B5cmlnaHQgMjAxMi0yMDEzIFRoZSBEb2pvIEZvdW5kYXRpb24gPGh0dHA6Ly9kb2pvZm91bmRhdGlvbi5vcmcvPlxuICogQmFzZWQgb24gVW5kZXJzY29yZS5qcyAxLjUuMiA8aHR0cDovL3VuZGVyc2NvcmVqcy5vcmcvTElDRU5TRT5cbiAqIENvcHlyaWdodCAyMDA5LTIwMTMgSmVyZW15IEFzaGtlbmFzLCBEb2N1bWVudENsb3VkIGFuZCBJbnZlc3RpZ2F0aXZlIFJlcG9ydGVycyAmIEVkaXRvcnNcbiAqIEF2YWlsYWJsZSB1bmRlciBNSVQgbGljZW5zZSA8aHR0cDovL2xvZGFzaC5jb20vbGljZW5zZT5cbiAqL1xudmFyIGlzRnVuY3Rpb24gPSByZXF1aXJlKCdsb2Rhc2guaXNmdW5jdGlvbicpLFxuICAgIGlzT2JqZWN0ID0gcmVxdWlyZSgnbG9kYXNoLmlzb2JqZWN0JyksXG4gICAgcmVOYXRpdmUgPSByZXF1aXJlKCdsb2Rhc2guX3JlbmF0aXZlJyk7XG5cbi8qKiBVc2VkIGFzIGEgc2FmZSByZWZlcmVuY2UgZm9yIGB1bmRlZmluZWRgIGluIHByZSBFUzUgZW52aXJvbm1lbnRzICovXG52YXIgdW5kZWZpbmVkO1xuXG4vKiogVXNlZCBmb3IgbmF0aXZlIG1ldGhvZCByZWZlcmVuY2VzICovXG52YXIgb2JqZWN0UHJvdG8gPSBPYmplY3QucHJvdG90eXBlO1xuXG4vKiogTmF0aXZlIG1ldGhvZCBzaG9ydGN1dHMgKi9cbnZhciBub3cgPSByZU5hdGl2ZS50ZXN0KG5vdyA9IERhdGUubm93KSAmJiBub3cgfHwgZnVuY3Rpb24oKSB7IHJldHVybiArbmV3IERhdGU7IH07XG5cbi8qIE5hdGl2ZSBtZXRob2Qgc2hvcnRjdXRzIGZvciBtZXRob2RzIHdpdGggdGhlIHNhbWUgbmFtZSBhcyBvdGhlciBgbG9kYXNoYCBtZXRob2RzICovXG52YXIgbmF0aXZlTWF4ID0gTWF0aC5tYXg7XG5cbi8qKlxuICogQ3JlYXRlcyBhIGZ1bmN0aW9uIHRoYXQgd2lsbCBkZWxheSB0aGUgZXhlY3V0aW9uIG9mIGBmdW5jYCB1bnRpbCBhZnRlclxuICogYHdhaXRgIG1pbGxpc2Vjb25kcyBoYXZlIGVsYXBzZWQgc2luY2UgdGhlIGxhc3QgdGltZSBpdCB3YXMgaW52b2tlZC5cbiAqIFByb3ZpZGUgYW4gb3B0aW9ucyBvYmplY3QgdG8gaW5kaWNhdGUgdGhhdCBgZnVuY2Agc2hvdWxkIGJlIGludm9rZWQgb25cbiAqIHRoZSBsZWFkaW5nIGFuZC9vciB0cmFpbGluZyBlZGdlIG9mIHRoZSBgd2FpdGAgdGltZW91dC4gU3Vic2VxdWVudCBjYWxsc1xuICogdG8gdGhlIGRlYm91bmNlZCBmdW5jdGlvbiB3aWxsIHJldHVybiB0aGUgcmVzdWx0IG9mIHRoZSBsYXN0IGBmdW5jYCBjYWxsLlxuICpcbiAqIE5vdGU6IElmIGBsZWFkaW5nYCBhbmQgYHRyYWlsaW5nYCBvcHRpb25zIGFyZSBgdHJ1ZWAgYGZ1bmNgIHdpbGwgYmUgY2FsbGVkXG4gKiBvbiB0aGUgdHJhaWxpbmcgZWRnZSBvZiB0aGUgdGltZW91dCBvbmx5IGlmIHRoZSB0aGUgZGVib3VuY2VkIGZ1bmN0aW9uIGlzXG4gKiBpbnZva2VkIG1vcmUgdGhhbiBvbmNlIGR1cmluZyB0aGUgYHdhaXRgIHRpbWVvdXQuXG4gKlxuICogQHN0YXRpY1xuICogQG1lbWJlck9mIF9cbiAqIEBjYXRlZ29yeSBGdW5jdGlvbnNcbiAqIEBwYXJhbSB7RnVuY3Rpb259IGZ1bmMgVGhlIGZ1bmN0aW9uIHRvIGRlYm91bmNlLlxuICogQHBhcmFtIHtudW1iZXJ9IHdhaXQgVGhlIG51bWJlciBvZiBtaWxsaXNlY29uZHMgdG8gZGVsYXkuXG4gKiBAcGFyYW0ge09iamVjdH0gW29wdGlvbnNdIFRoZSBvcHRpb25zIG9iamVjdC5cbiAqIEBwYXJhbSB7Ym9vbGVhbn0gW29wdGlvbnMubGVhZGluZz1mYWxzZV0gU3BlY2lmeSBleGVjdXRpb24gb24gdGhlIGxlYWRpbmcgZWRnZSBvZiB0aGUgdGltZW91dC5cbiAqIEBwYXJhbSB7bnVtYmVyfSBbb3B0aW9ucy5tYXhXYWl0XSBUaGUgbWF4aW11bSB0aW1lIGBmdW5jYCBpcyBhbGxvd2VkIHRvIGJlIGRlbGF5ZWQgYmVmb3JlIGl0J3MgY2FsbGVkLlxuICogQHBhcmFtIHtib29sZWFufSBbb3B0aW9ucy50cmFpbGluZz10cnVlXSBTcGVjaWZ5IGV4ZWN1dGlvbiBvbiB0aGUgdHJhaWxpbmcgZWRnZSBvZiB0aGUgdGltZW91dC5cbiAqIEByZXR1cm5zIHtGdW5jdGlvbn0gUmV0dXJucyB0aGUgbmV3IGRlYm91bmNlZCBmdW5jdGlvbi5cbiAqIEBleGFtcGxlXG4gKlxuICogLy8gYXZvaWQgY29zdGx5IGNhbGN1bGF0aW9ucyB3aGlsZSB0aGUgd2luZG93IHNpemUgaXMgaW4gZmx1eFxuICogdmFyIGxhenlMYXlvdXQgPSBfLmRlYm91bmNlKGNhbGN1bGF0ZUxheW91dCwgMTUwKTtcbiAqIGpRdWVyeSh3aW5kb3cpLm9uKCdyZXNpemUnLCBsYXp5TGF5b3V0KTtcbiAqXG4gKiAvLyBleGVjdXRlIGBzZW5kTWFpbGAgd2hlbiB0aGUgY2xpY2sgZXZlbnQgaXMgZmlyZWQsIGRlYm91bmNpbmcgc3Vic2VxdWVudCBjYWxsc1xuICogalF1ZXJ5KCcjcG9zdGJveCcpLm9uKCdjbGljaycsIF8uZGVib3VuY2Uoc2VuZE1haWwsIDMwMCwge1xuICogICAnbGVhZGluZyc6IHRydWUsXG4gKiAgICd0cmFpbGluZyc6IGZhbHNlXG4gKiB9KTtcbiAqXG4gKiAvLyBlbnN1cmUgYGJhdGNoTG9nYCBpcyBleGVjdXRlZCBvbmNlIGFmdGVyIDEgc2Vjb25kIG9mIGRlYm91bmNlZCBjYWxsc1xuICogdmFyIHNvdXJjZSA9IG5ldyBFdmVudFNvdXJjZSgnL3N0cmVhbScpO1xuICogc291cmNlLmFkZEV2ZW50TGlzdGVuZXIoJ21lc3NhZ2UnLCBfLmRlYm91bmNlKGJhdGNoTG9nLCAyNTAsIHtcbiAqICAgJ21heFdhaXQnOiAxMDAwXG4gKiB9LCBmYWxzZSk7XG4gKi9cbmZ1bmN0aW9uIGRlYm91bmNlKGZ1bmMsIHdhaXQsIG9wdGlvbnMpIHtcbiAgdmFyIGFyZ3MsXG4gICAgICBtYXhUaW1lb3V0SWQsXG4gICAgICByZXN1bHQsXG4gICAgICBzdGFtcCxcbiAgICAgIHRoaXNBcmcsXG4gICAgICB0aW1lb3V0SWQsXG4gICAgICB0cmFpbGluZ0NhbGwsXG4gICAgICBsYXN0Q2FsbGVkID0gMCxcbiAgICAgIG1heFdhaXQgPSBmYWxzZSxcbiAgICAgIHRyYWlsaW5nID0gdHJ1ZTtcblxuICBpZiAoIWlzRnVuY3Rpb24oZnVuYykpIHtcbiAgICB0aHJvdyBuZXcgVHlwZUVycm9yO1xuICB9XG4gIHdhaXQgPSBuYXRpdmVNYXgoMCwgd2FpdCkgfHwgMDtcbiAgaWYgKG9wdGlvbnMgPT09IHRydWUpIHtcbiAgICB2YXIgbGVhZGluZyA9IHRydWU7XG4gICAgdHJhaWxpbmcgPSBmYWxzZTtcbiAgfSBlbHNlIGlmIChpc09iamVjdChvcHRpb25zKSkge1xuICAgIGxlYWRpbmcgPSBvcHRpb25zLmxlYWRpbmc7XG4gICAgbWF4V2FpdCA9ICdtYXhXYWl0JyBpbiBvcHRpb25zICYmIChuYXRpdmVNYXgod2FpdCwgb3B0aW9ucy5tYXhXYWl0KSB8fCAwKTtcbiAgICB0cmFpbGluZyA9ICd0cmFpbGluZycgaW4gb3B0aW9ucyA/IG9wdGlvbnMudHJhaWxpbmcgOiB0cmFpbGluZztcbiAgfVxuICB2YXIgZGVsYXllZCA9IGZ1bmN0aW9uKCkge1xuICAgIHZhciByZW1haW5pbmcgPSB3YWl0IC0gKG5vdygpIC0gc3RhbXApO1xuICAgIGlmIChyZW1haW5pbmcgPD0gMCkge1xuICAgICAgaWYgKG1heFRpbWVvdXRJZCkge1xuICAgICAgICBjbGVhclRpbWVvdXQobWF4VGltZW91dElkKTtcbiAgICAgIH1cbiAgICAgIHZhciBpc0NhbGxlZCA9IHRyYWlsaW5nQ2FsbDtcbiAgICAgIG1heFRpbWVvdXRJZCA9IHRpbWVvdXRJZCA9IHRyYWlsaW5nQ2FsbCA9IHVuZGVmaW5lZDtcbiAgICAgIGlmIChpc0NhbGxlZCkge1xuICAgICAgICBsYXN0Q2FsbGVkID0gbm93KCk7XG4gICAgICAgIHJlc3VsdCA9IGZ1bmMuYXBwbHkodGhpc0FyZywgYXJncyk7XG4gICAgICB9XG4gICAgfSBlbHNlIHtcbiAgICAgIHRpbWVvdXRJZCA9IHNldFRpbWVvdXQoZGVsYXllZCwgcmVtYWluaW5nKTtcbiAgICB9XG4gIH07XG5cbiAgdmFyIG1heERlbGF5ZWQgPSBmdW5jdGlvbigpIHtcbiAgICBpZiAodGltZW91dElkKSB7XG4gICAgICBjbGVhclRpbWVvdXQodGltZW91dElkKTtcbiAgICB9XG4gICAgbWF4VGltZW91dElkID0gdGltZW91dElkID0gdHJhaWxpbmdDYWxsID0gdW5kZWZpbmVkO1xuICAgIGlmICh0cmFpbGluZyB8fCAobWF4V2FpdCAhPT0gd2FpdCkpIHtcbiAgICAgIGxhc3RDYWxsZWQgPSBub3coKTtcbiAgICAgIHJlc3VsdCA9IGZ1bmMuYXBwbHkodGhpc0FyZywgYXJncyk7XG4gICAgfVxuICB9O1xuXG4gIHJldHVybiBmdW5jdGlvbigpIHtcbiAgICBhcmdzID0gYXJndW1lbnRzO1xuICAgIHN0YW1wID0gbm93KCk7XG4gICAgdGhpc0FyZyA9IHRoaXM7XG4gICAgdHJhaWxpbmdDYWxsID0gdHJhaWxpbmcgJiYgKHRpbWVvdXRJZCB8fCAhbGVhZGluZyk7XG5cbiAgICBpZiAobWF4V2FpdCA9PT0gZmFsc2UpIHtcbiAgICAgIHZhciBsZWFkaW5nQ2FsbCA9IGxlYWRpbmcgJiYgIXRpbWVvdXRJZDtcbiAgICB9IGVsc2Uge1xuICAgICAgaWYgKCFtYXhUaW1lb3V0SWQgJiYgIWxlYWRpbmcpIHtcbiAgICAgICAgbGFzdENhbGxlZCA9IHN0YW1wO1xuICAgICAgfVxuICAgICAgdmFyIHJlbWFpbmluZyA9IG1heFdhaXQgLSAoc3RhbXAgLSBsYXN0Q2FsbGVkKTtcbiAgICAgIGlmIChyZW1haW5pbmcgPD0gMCkge1xuICAgICAgICBpZiAobWF4VGltZW91dElkKSB7XG4gICAgICAgICAgbWF4VGltZW91dElkID0gY2xlYXJUaW1lb3V0KG1heFRpbWVvdXRJZCk7XG4gICAgICAgIH1cbiAgICAgICAgbGFzdENhbGxlZCA9IHN0YW1wO1xuICAgICAgICByZXN1bHQgPSBmdW5jLmFwcGx5KHRoaXNBcmcsIGFyZ3MpO1xuICAgICAgfVxuICAgICAgZWxzZSBpZiAoIW1heFRpbWVvdXRJZCkge1xuICAgICAgICBtYXhUaW1lb3V0SWQgPSBzZXRUaW1lb3V0KG1heERlbGF5ZWQsIHJlbWFpbmluZyk7XG4gICAgICB9XG4gICAgfVxuICAgIGlmICghdGltZW91dElkICYmIHdhaXQgIT09IG1heFdhaXQpIHtcbiAgICAgIHRpbWVvdXRJZCA9IHNldFRpbWVvdXQoZGVsYXllZCwgd2FpdCk7XG4gICAgfVxuICAgIGlmIChsZWFkaW5nQ2FsbCkge1xuICAgICAgcmVzdWx0ID0gZnVuYy5hcHBseSh0aGlzQXJnLCBhcmdzKTtcbiAgICB9XG4gICAgcmV0dXJuIHJlc3VsdDtcbiAgfTtcbn1cblxubW9kdWxlLmV4cG9ydHMgPSBkZWJvdW5jZTtcbiIsIi8qKlxuICogQGxpY2Vuc2VcbiAqIExvLURhc2ggMi4wLjAgPGh0dHA6Ly9sb2Rhc2guY29tLz5cbiAqIENvcHlyaWdodCAyMDEyLTIwMTMgVGhlIERvam8gRm91bmRhdGlvbiA8aHR0cDovL2Rvam9mb3VuZGF0aW9uLm9yZy8+XG4gKiBCYXNlZCBvbiBVbmRlcnNjb3JlLmpzIDEuNS4yIDxodHRwOi8vdW5kZXJzY29yZWpzLm9yZy9MSUNFTlNFPlxuICogQ29weXJpZ2h0IDIwMDktMjAxMyBKZXJlbXkgQXNoa2VuYXMsIERvY3VtZW50Q2xvdWQgYW5kIEludmVzdGlnYXRpdmUgUmVwb3J0ZXJzICYgRWRpdG9yc1xuICogQXZhaWxhYmxlIHVuZGVyIE1JVCBsaWNlbnNlIDxodHRwOi8vbG9kYXNoLmNvbS9saWNlbnNlPlxuICovXG5cbi8qKiBVc2VkIGZvciBuYXRpdmUgbWV0aG9kIHJlZmVyZW5jZXMgKi9cbnZhciBvYmplY3RQcm90byA9IE9iamVjdC5wcm90b3R5cGU7XG5cbi8qKiBVc2VkIHRvIGRldGVjdCBpZiBhIG1ldGhvZCBpcyBuYXRpdmUgKi9cbnZhciByZU5hdGl2ZSA9IFJlZ0V4cCgnXicgK1xuICBTdHJpbmcob2JqZWN0UHJvdG8udmFsdWVPZilcbiAgICAucmVwbGFjZSgvWy4qKz9eJHt9KCl8W1xcXVxcXFxdL2csICdcXFxcJCYnKVxuICAgIC5yZXBsYWNlKC92YWx1ZU9mfGZvciBbXlxcXV0rL2csICcuKz8nKSArICckJ1xuKTtcblxubW9kdWxlLmV4cG9ydHMgPSByZU5hdGl2ZTtcbiIsIi8qKlxuICogQGxpY2Vuc2VcbiAqIExvLURhc2ggMi4wLjAgPGh0dHA6Ly9sb2Rhc2guY29tLz5cbiAqIENvcHlyaWdodCAyMDEyLTIwMTMgVGhlIERvam8gRm91bmRhdGlvbiA8aHR0cDovL2Rvam9mb3VuZGF0aW9uLm9yZy8+XG4gKiBCYXNlZCBvbiBVbmRlcnNjb3JlLmpzIDEuNS4yIDxodHRwOi8vdW5kZXJzY29yZWpzLm9yZy9MSUNFTlNFPlxuICogQ29weXJpZ2h0IDIwMDktMjAxMyBKZXJlbXkgQXNoa2VuYXMsIERvY3VtZW50Q2xvdWQgYW5kIEludmVzdGlnYXRpdmUgUmVwb3J0ZXJzICYgRWRpdG9yc1xuICogQXZhaWxhYmxlIHVuZGVyIE1JVCBsaWNlbnNlIDxodHRwOi8vbG9kYXNoLmNvbS9saWNlbnNlPlxuICovXG5cbi8qKlxuICogQ2hlY2tzIGlmIGB2YWx1ZWAgaXMgYSBmdW5jdGlvbi5cbiAqXG4gKiBAc3RhdGljXG4gKiBAbWVtYmVyT2YgX1xuICogQGNhdGVnb3J5IE9iamVjdHNcbiAqIEBwYXJhbSB7Kn0gdmFsdWUgVGhlIHZhbHVlIHRvIGNoZWNrLlxuICogQHJldHVybnMge2Jvb2xlYW59IFJldHVybnMgYHRydWVgIGlmIHRoZSBgdmFsdWVgIGlzIGEgZnVuY3Rpb24sIGVsc2UgYGZhbHNlYC5cbiAqIEBleGFtcGxlXG4gKlxuICogXy5pc0Z1bmN0aW9uKF8pO1xuICogLy8gPT4gdHJ1ZVxuICovXG5mdW5jdGlvbiBpc0Z1bmN0aW9uKHZhbHVlKSB7XG4gIHJldHVybiB0eXBlb2YgdmFsdWUgPT0gJ2Z1bmN0aW9uJztcbn1cblxubW9kdWxlLmV4cG9ydHMgPSBpc0Z1bmN0aW9uO1xuIiwiLyoqXG4gKiBAbGljZW5zZVxuICogTG8tRGFzaCAyLjAuMCA8aHR0cDovL2xvZGFzaC5jb20vPlxuICogQ29weXJpZ2h0IDIwMTItMjAxMyBUaGUgRG9qbyBGb3VuZGF0aW9uIDxodHRwOi8vZG9qb2ZvdW5kYXRpb24ub3JnLz5cbiAqIEJhc2VkIG9uIFVuZGVyc2NvcmUuanMgMS41LjIgPGh0dHA6Ly91bmRlcnNjb3JlanMub3JnL0xJQ0VOU0U+XG4gKiBDb3B5cmlnaHQgMjAwOS0yMDEzIEplcmVteSBBc2hrZW5hcywgRG9jdW1lbnRDbG91ZCBhbmQgSW52ZXN0aWdhdGl2ZSBSZXBvcnRlcnMgJiBFZGl0b3JzXG4gKiBBdmFpbGFibGUgdW5kZXIgTUlUIGxpY2Vuc2UgPGh0dHA6Ly9sb2Rhc2guY29tL2xpY2Vuc2U+XG4gKi9cbnZhciBvYmplY3RUeXBlcyA9IHJlcXVpcmUoJ2xvZGFzaC5fb2JqZWN0dHlwZXMnKTtcblxuLyoqXG4gKiBDaGVja3MgaWYgYHZhbHVlYCBpcyB0aGUgbGFuZ3VhZ2UgdHlwZSBvZiBPYmplY3QuXG4gKiAoZS5nLiBhcnJheXMsIGZ1bmN0aW9ucywgb2JqZWN0cywgcmVnZXhlcywgYG5ldyBOdW1iZXIoMClgLCBhbmQgYG5ldyBTdHJpbmcoJycpYClcbiAqXG4gKiBAc3RhdGljXG4gKiBAbWVtYmVyT2YgX1xuICogQGNhdGVnb3J5IE9iamVjdHNcbiAqIEBwYXJhbSB7Kn0gdmFsdWUgVGhlIHZhbHVlIHRvIGNoZWNrLlxuICogQHJldHVybnMge2Jvb2xlYW59IFJldHVybnMgYHRydWVgIGlmIHRoZSBgdmFsdWVgIGlzIGFuIG9iamVjdCwgZWxzZSBgZmFsc2VgLlxuICogQGV4YW1wbGVcbiAqXG4gKiBfLmlzT2JqZWN0KHt9KTtcbiAqIC8vID0+IHRydWVcbiAqXG4gKiBfLmlzT2JqZWN0KFsxLCAyLCAzXSk7XG4gKiAvLyA9PiB0cnVlXG4gKlxuICogXy5pc09iamVjdCgxKTtcbiAqIC8vID0+IGZhbHNlXG4gKi9cbmZ1bmN0aW9uIGlzT2JqZWN0KHZhbHVlKSB7XG4gIC8vIGNoZWNrIGlmIHRoZSB2YWx1ZSBpcyB0aGUgRUNNQVNjcmlwdCBsYW5ndWFnZSB0eXBlIG9mIE9iamVjdFxuICAvLyBodHRwOi8vZXM1LmdpdGh1Yi5pby8jeDhcbiAgLy8gYW5kIGF2b2lkIGEgVjggYnVnXG4gIC8vIGh0dHA6Ly9jb2RlLmdvb2dsZS5jb20vcC92OC9pc3N1ZXMvZGV0YWlsP2lkPTIyOTFcbiAgcmV0dXJuICEhKHZhbHVlICYmIG9iamVjdFR5cGVzW3R5cGVvZiB2YWx1ZV0pO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IGlzT2JqZWN0O1xuIiwiLyoqXG4gKiBAbGljZW5zZVxuICogTG8tRGFzaCAyLjAuMCA8aHR0cDovL2xvZGFzaC5jb20vPlxuICogQ29weXJpZ2h0IDIwMTItMjAxMyBUaGUgRG9qbyBGb3VuZGF0aW9uIDxodHRwOi8vZG9qb2ZvdW5kYXRpb24ub3JnLz5cbiAqIEJhc2VkIG9uIFVuZGVyc2NvcmUuanMgMS41LjIgPGh0dHA6Ly91bmRlcnNjb3JlanMub3JnL0xJQ0VOU0U+XG4gKiBDb3B5cmlnaHQgMjAwOS0yMDEzIEplcmVteSBBc2hrZW5hcywgRG9jdW1lbnRDbG91ZCBhbmQgSW52ZXN0aWdhdGl2ZSBSZXBvcnRlcnMgJiBFZGl0b3JzXG4gKiBBdmFpbGFibGUgdW5kZXIgTUlUIGxpY2Vuc2UgPGh0dHA6Ly9sb2Rhc2guY29tL2xpY2Vuc2U+XG4gKi9cblxuLyoqIFVzZWQgdG8gZGV0ZXJtaW5lIGlmIHZhbHVlcyBhcmUgb2YgdGhlIGxhbmd1YWdlIHR5cGUgT2JqZWN0ICovXG52YXIgb2JqZWN0VHlwZXMgPSB7XG4gICdib29sZWFuJzogZmFsc2UsXG4gICdmdW5jdGlvbic6IHRydWUsXG4gICdvYmplY3QnOiB0cnVlLFxuICAnbnVtYmVyJzogZmFsc2UsXG4gICdzdHJpbmcnOiBmYWxzZSxcbiAgJ3VuZGVmaW5lZCc6IGZhbHNlXG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IG9iamVjdFR5cGVzO1xuIl19
;