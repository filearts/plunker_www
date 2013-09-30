;(function (exports) {

//List from node-htmlparser
var singleTags = {
  area: 1,
  base: 1,
  basefont: 1,
  br: 1,
  col: 1,
  frame: 1,
  hr: 1,
  img: 1,
  input: 1,
  isindex: 1,
  link: 1,
  meta: 1,
  param: 1,
  embed: 1
};

var expr = {
  upperCaseChars: /([A-Z])/g,
  breakBetweenTags: /(<(\/?\w+).*?>)(?=<(?!\/\2))/gi,
  singleTag: (function() {
    var tags = [];
    for (var i in singleTags) {
      tags.push(i);
    }
    return new RegExp('<' + tags.join('|<'), 'i');
  })()
};

var uncanon = function(str, letter) {
  return '-' + letter.toLowerCase();
};

var HTMLEncode = function(text) { return text; }; // Noop

exports.stringifyElement = function stringifyElement(element) {
  var tagName = element.tagName.toLowerCase(),
      ret = {
        start: "<" + tagName,
        end:''
      },
      attributes = [],
      i,
      attribute = null;

  if (element.attributes.length) {
    ret.start += " ";
    for (i = 0; i<element.attributes.length; i++) {
      attribute = element.attributes.item(i);
      attributes.push(attribute.name + '="' +
                      HTMLEncode(attribute.nodeValue, true) + '"');
    }
  }
  ret.start += attributes.join(" ");

  if (singleTags[tagName]) {
    ret.start += " />";
    ret.end = '';
  } else {
    ret.start += ">";
    ret.end = "</" + tagName + ">";
  }

  return ret;
};

var rawTextElements = /SCRIPT|STYLE/i;

function stringifyDoctype (doctype) {
  if (doctype.ownerDocument && doctype.ownerDocument.fullDT) {
    return doctype.ownerDocument.fullDT;
  }

  var dt = '<!DOCTYPE ' + doctype.name;
  if (doctype.publicId) {
    // Public ID may never contain double quotes, so this is always safe.
    dt += ' PUBLIC "' + doctype.publicId + '" ';
  }
  if (!doctype.publicId && doctype.systemId) {
    dt += ' SYSTEM ';
  }
  if (doctype.systemId) {
    // System ID may contain double quotes OR single quotes, not never both.
    if (doctype.systemId.indexOf('"') > -1) {
      dt += "'" + doctype.systemId + "'";
    } else {
      dt += '"' + doctype.systemId + '"';
    }
  }
  dt += '>';
  return dt;
}

exports.makeHtmlGenerator = function makeHtmlGenerator(indentUnit, eol) {
  indentUnit = indentUnit || "";
  eol = eol || "";

  return function generateHtmlRecursive(node, rawText, curIndent) {
    var ret = "", parent, current, i, children;
    curIndent = curIndent || "";
    if (node) {
      if (node.nodeType &&
          node.nodeType === node.ENTITY_REFERENCE_NODE) {
        node = node.entity;
      }

      var childNodesRawText = rawText || rawTextElements.test(node.nodeName);
      
      switch (node.nodeType) {
        case node.ELEMENT_NODE:
          if (node.tagName === "TEMPLATE") {
            children = node.content.childNodes;
            childNodesRawText = true;
          } else {
            children = node.childNodes;
          }
          
          current = exports.stringifyElement(node);
          
          if (childNodesRawText) {
            ret += curIndent + current.start;
          } else {
            ret += curIndent + current.start;
          }
          
          if (node.nodeName === "HTML") ret += eol;

          if (children.length > 0) {
            if (children[0].nodeType !== node.TEXT_NODE) {
              ret += eol;
            }
            for (i=0; i<children.length; i++) {
              ret += generateHtmlRecursive(children[i], childNodesRawText, curIndent + indentUnit) || (i === 0 && children.length > 1 ? eol : "");
            }
            if (children[children.length - 1].nodeType !== node.TEXT_NODE || ret.charAt(ret.length - 1) === eol) {
              ret += curIndent;
            }
            ret += current.end + eol;
          } else {
            ret += ((rawText ? node.nodeValue : HTMLEncode(node.nodeValue, false)) || '') + current.end + eol;
          }
          
          if (node.nodeName === "HEAD" || node.nodeName === "BODY") ret += eol;
          
          break;
        case node.TEXT_NODE:
          // Skip pure whitespace nodes if we're indenting
          if (!indentUnit || !/^[\s\n]*$/.test(node.nodeValue)) {
            ret += (rawText ? node.nodeValue : HTMLEncode(node.nodeValue, false)) || '';
          }
          break;
        case node.COMMENT_NODE:
          ret += curIndent + '<!--' + node.nodeValue + '-->' + eol;
          break;
        case node.DOCUMENT_NODE:
          for (i=0; i<node.childNodes.length; i++) {
            ret += generateHtmlRecursive(node.childNodes[i], childNodesRawText, curIndent);
          }
          break;
        case node.DOCUMENT_TYPE_NODE:
          ret += stringifyDoctype(node);
          ret += eol; // Two newlines after doctype
        break;
      }
    }
    return ret;
  };
};

exports.domToHtml = function(dom, noformat, raw) {
  var htmlGenerator = exports.makeHtmlGenerator(noformat ? "" : "  ",
                                                noformat ? "" : "\n");
  if (dom.toArray) {
    // node list
    dom = dom.toArray();
  }
  if (typeof dom.length !== 'undefined') {
    var ret = "";
    for (var i=0,len=dom.length; i<len; i++) {
      ret += htmlGenerator(dom[i], raw);
    }
    return ret;
  } else {
    // single node
    return htmlGenerator(dom, raw);
  }
};


})(typeof exports === "object" ? exports : dominatrix = {});