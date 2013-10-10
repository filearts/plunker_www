(function(){
(function(){var r={exports:{}},e=r.exports;e.name="text",e.uri="http://sharejs.org/types/textv1",e.create=function(r){if(null!=r&&"string"!=typeof r)throw Error("Initial data must be a string");return r||""};var t=Array.isArray||function(r){return"[object Array]"===Object.prototype.toString.call(r)},n=function(r){if(!t(r))throw Error("Op must be an array of components");for(var e=null,n=0;r.length>n;n++){var o=r[n];switch(typeof o){case"object":if(!("number"==typeof o.d&&o.d>0))throw Error("Object components must be deletes of size > 0");break;case"string":if(!(o.length>0))throw Error("Inserts cannot be empty");break;case"number":if(!(o>0))throw Error("Skip components must be >0");if("number"==typeof e)throw Error("Adjacent skip components should be combined")}e=o}if("number"==typeof e)throw Error("Op has a trailing skip")},o=function(r){return function(e){return e&&0!==e.d?0===r.length?r.push(e):typeof e==typeof r[r.length-1]?"object"==typeof e?r[r.length-1].d+=e.d:r[r.length-1]+=e:r.push(e):void 0}},s=function(r){var e=0,t=0,n=function(n,o){if(e===r.length)return-1===n?null:n;var s,i=r[e];return"number"==typeof i?-1===n||n>=i-t?(s=i-t,++e,t=0,s):(t+=n,n):"string"==typeof i?-1===n||"i"===o||n>=i.length-t?(s=i.slice(t),++e,t=0,s):(s=i.slice(t,t+n),t+=n,s):-1===n||"d"===o||n>=i.d-t?(s={d:i.d-t},++e,t=0,s):(t+=n,{d:n})},o=function(){return r[e]};return[n,o]},i=function(r){return"number"==typeof r?r:r.length||r.d},a=function(r){return r.length>0&&"number"==typeof r[r.length-1]&&r.pop(),r};e.normalize=function(r){for(var e=[],t=o(e),n=0;r.length>n;n++)t(r[n]);return a(e)},e.apply=function(r,e){if("string"!=typeof r)throw Error("Snapshot should be a string");n(e);for(var t=[],o=0;e.length>o;o++){var s=e[o];switch(typeof s){case"number":if(s>r.length)throw Error("The op is too long for this document");t.push(r.slice(0,s)),r=r.slice(s);break;case"string":t.push(s);break;case"object":r=r.slice(s.d)}}return t.join("")+r},e.transform=function(r,e,t){if("left"!=t&&"right"!=t)throw Error("side ("+t+") must be 'left' or 'right'");n(r),n(e);for(var c=[],f=o(c),u=s(r),h=u[0],p=u[1],b=0;e.length>b;b++){var l,g,m=e[b];switch(typeof m){case"number":for(l=m;l>0;)g=h(l,"i"),f(g),"string"!=typeof g&&(l-=i(g));break;case"string":"left"===t&&"string"==typeof p()&&f(h(-1)),f(m.length);break;case"object":for(l=m.d;l>0;)switch(g=h(l,"i"),typeof g){case"number":l-=g;break;case"string":f(g);break;case"object":l-=g.d}}}for(;m=h(-1);)f(m);return a(c)},e.compose=function(r,e){n(r),n(e);for(var t=[],c=o(t),f=s(r)[0],u=0;e.length>u;u++){var h,p,b=e[u];switch(typeof b){case"number":for(h=b;h>0;)p=f(h,"d"),c(p),"object"!=typeof p&&(h-=i(p));break;case"string":c(b);break;case"object":for(h=b.d;h>0;)switch(p=f(h,"d"),typeof p){case"number":c({d:p}),h-=p;break;case"string":h-=p.length;break;case"object":c(p)}}}for(;b=f(-1);)c(b);return a(t)};var c=function(r,e){for(var t=0,n=0;e.length>n;n++){var o=e[n];if(t>=r)break;switch(typeof o){case"number":if(t+o>=r)return r;t+=o;break;case"string":t+=o.length,r+=o.length;break;case"object":r-=Math.min(o.d,r-t)}}return r};e.transformCursor=function(r,e,t){var n=0;if(t){for(var o=0;e.length>o;o++){var s=e[o];switch(typeof s){case"number":n+=s;break;case"string":n+=s.length}}return[n,n]}return[c(r[0],e),c(r[1],e)]};var f=window.ottypes=window.ottypes||{},u=r.exports;f[u.name]=u,u.uri&&(f[u.uri]=u)})();// Text document API for the 'text' type.

// The API implements the standard text API methods. In particular:
//
// - getLength() returns the length of the document in characters
// - getText() returns a string of the document
// - insert(pos, text, [callback]) inserts text at position pos in the document
// - remove(pos, length, [callback]) removes length characters at position pos
//
// Events are implemented by just adding the appropriate methods to your
// context object.
// onInsert(pos, text): Called when text is inserted.
// onRemove(pos, length): Called when text is removed.

var _types = (typeof brequire !== 'undefined') ?
  brequire('ottypes') : window.ottypes;

_types['http://sharejs.org/types/textv1'].api = {
  provides: {text: true},

  // Returns the number of characters in the string
  getLength: function() { return this.getSnapshot().length; },


  // Returns the text content of the document
  get: function() { return this.getSnapshot(); },

  getText: function() {
    console.warn("`getText()` is deprecated; use `get()` instead.");
    return this.get();
  },

  // Insert the specified text at the given position in the document
  insert: function(pos, text, callback) {
    return this.submitOp([pos, text], callback);
  },

  remove: function(pos, length, callback) {
    return this.submitOp([pos, {d:length}], callback);
  },

  // When you use this API, you should implement these two methods
  // in your editing context.
  //onInsert: function(pos, text) {},
  //onRemove: function(pos, removedLength) {},

  _onOp: function(op) {
    var pos = 0;
    var spos = 0;
    for (var i = 0; i < op.length; i++) {
      var component = op[i];
      switch (typeof component) {
        case 'number':
          pos += component;
          spos += component;
          break;
        case 'string':
          if (this.onInsert) this.onInsert(pos, component);
          pos += component.length;
          break;
        case 'object':
          if (this.onRemove) this.onRemove(pos, component.d);
          spos += component.d;
      }
    }
  }
};
(function(){var e={exports:{}},i=e.exports;i._bootstrapTransform=function(e,i,n,r){var t,l;return t=function(e,n,r,t){return i(r,e,n,"left"),i(t,n,e,"right")},e.transformX=e.transformX=l=function(e,i){var o,p,d,f,s,a,u,c,h,v,g,m,y,w,O,b,k,E,x;for(n(e),n(i),s=[],v=0,w=i.length;w>v;v++){for(h=i[v],f=[],o=0;e.length>o;){if(a=[],t(e[o],h,f,a),o++,1!==a.length){if(0===a.length){for(E=e.slice(o),g=0,O=E.length;O>g;g++)p=E[g],r(f,p);h=null;break}for(x=l(e.slice(o),a),d=x[0],c=x[1],m=0,b=d.length;b>m;m++)p=d[m],r(f,p);for(y=0,k=c.length;k>y;y++)u=c[y],r(s,u);h=null;break}h=a[0]}null!=h&&r(s,h),e=f}return[e,s]},e.transform=e.transform=function(e,n,r){if("left"!==r&&"right"!==r)throw Error("type must be 'left' or 'right'");return 0===n.length?e:1===e.length&&1===n.length?i([],e[0],n[0],r):"left"===r?l(e,n)[0]:l(n,e)[1]}};var n,r,t,l,o,p,d,f;p={name:"text-old",uri:"http://sharejs.org/types/textv0",create:function(){return""}},o=function(e,i,n){return e.slice(0,i)+n+e.slice(i)},r=function(e){var i,n;if("number"!=typeof e.p)throw Error("component missing position field");if(n=typeof e.i,i=typeof e.d,!("string"===n^"string"===i))throw Error("component needs an i or d field");if(!(e.p>=0))throw Error("position cannot be negative")},t=function(e){var i,n,t;for(n=0,t=e.length;t>n;n++)i=e[n],r(i);return!0},p.apply=function(e,i){var n,r,l,p;for(t(i),l=0,p=i.length;p>l;l++)if(n=i[l],null!=n.i)e=o(e,n.p,n.i);else{if(r=e.slice(n.p,n.p+n.d.length),n.d!==r)throw Error("Delete component '"+n.d+"' does not match deleted text '"+r+"'");e=e.slice(0,n.p)+e.slice(n.p+n.d.length)}return e},p._append=n=function(e,i){var n,r,t;if(""!==i.i&&""!==i.d)return 0===e.length?e.push(i):(n=e[e.length-1],null!=n.i&&null!=i.i&&n.p<=(r=i.p)&&n.p+n.i.length>=r?e[e.length-1]={i:o(n.i,i.p-n.p,i.i),p:n.p}:null!=n.d&&null!=i.d&&i.p<=(t=n.p)&&i.p+i.d.length>=t?e[e.length-1]={d:o(i.d,n.p-i.p,n.d),p:i.p}:e.push(i))},p.compose=function(e,i){var r,l,o,p;for(t(e),t(i),l=e.slice(),o=0,p=i.length;p>o;o++)r=i[o],n(l,r);return l},p.compress=function(e){return p.compose([],e)},p.normalize=function(e){var i,r,t,l,o;for(r=[],(null!=e.i||null!=e.p)&&(e=[e]),t=0,l=e.length;l>t;t++)i=e[t],null==(o=i.p)&&(i.p=0),n(r,i);return r},f=function(e,i,n){return null!=i.i?e>i.p||i.p===e&&n?e+i.i.length:e:i.p>=e?e:i.p+i.d.length>=e?i.p:e-i.d.length},p.transformCursor=function(e,i,n){var r,t,l,o;for(t="right"===n,l=0,o=i.length;o>l;l++)r=i[l],e=f(e,r,t);return e},p._tc=d=function(e,i,r,l){var o,p,d,s,a,u;if(t([i]),t([r]),null!=i.i)n(e,{i:i.i,p:f(i.p,r,"right"===l)});else if(null!=r.i)u=i.d,i.p<r.p&&(n(e,{d:u.slice(0,r.p-i.p),p:i.p}),u=u.slice(r.p-i.p)),""!==u&&n(e,{d:u,p:i.p+r.i.length});else if(i.p>=r.p+r.d.length)n(e,{d:i.d,p:i.p-r.d.length});else if(i.p+i.d.length<=r.p)n(e,i);else{if(s={d:"",p:i.p},i.p<r.p&&(s.d=i.d.slice(0,r.p-i.p)),i.p+i.d.length>r.p+r.d.length&&(s.d+=i.d.slice(r.p+r.d.length-i.p)),d=Math.max(i.p,r.p),p=Math.min(i.p+i.d.length,r.p+r.d.length),o=i.d.slice(d-i.p,p-i.p),a=r.d.slice(d-r.p,p-r.p),o!==a)throw Error("Delete ops delete different text in the same region of the document");""!==s.d&&(s.p=f(s.p,r),n(e,s))}return e},l=function(e){return null!=e.i?{d:e.i,p:e.p}:{i:e.d,p:e.p}},p.invert=function(e){var i,n,r,t,o;for(t=e.slice().reverse(),o=[],n=0,r=t.length;r>n;n++)i=t[n],o.push(l(i));return o},"undefined"==typeof brequire?i._bootstrapTransform(p,p.transformComponent,p.checkValidOp,p.append):brequire("./helpers")._bootstrapTransform(p,p.transformComponent,p.checkValidOp,p.append),e.exports=p;var s=function(e){return"[object Array]"==Object.prototype.toString.call(e)},a=function(e){return JSON.parse(JSON.stringify(e))},p="undefined"!=typeof brequire?brequire("./text-old"):window.ottypes.text,u={name:"json0",uri:"http://sharejs.org/types/JSONv0"};u.create=function(e){return void 0===e?null:e},u.invertComponent=function(e){var i={p:e.p};return void 0!==e.si&&(i.sd=e.si),void 0!==e.sd&&(i.si=e.sd),void 0!==e.oi&&(i.od=e.oi),void 0!==e.od&&(i.oi=e.od),void 0!==e.li&&(i.ld=e.li),void 0!==e.ld&&(i.li=e.ld),void 0!==e.na&&(i.na=-e.na),void 0!==e.lm&&(i.lm=e.p[e.p.length-1],i.p=e.p.slice(0,e.p.length-1).concat([e.lm])),i},u.invert=function(e){for(var i=e.slice().reverse(),n=[],r=0;i.length>r;r++)n.push(u.invertComponent(i[r]));return n},u.checkValidOp=function(e){for(var i=0;e.length>i;i++)if(!s(e[i].p))throw Error("Missing path")},u.checkList=function(e){if(!s(e))throw Error("Referenced element not a list")},u.checkObj=function(e){if(e.constructor!==Object)throw Error("Referenced element not an object (it was "+JSON.stringify(e)+")")},u.apply=function(e,i){u.checkValidOp(i),i=a(i);for(var n={data:e},r=0;i.length>r;r++){for(var t=i[r],l=null,o=null,p=n,d="data",f=0;t.p.length>f;f++){var s=t.p[f];if(l=p,o=d,p=p[d],d=s,null==l)throw Error("Path invalid")}if(void 0!==t.na){if("number"!=typeof p[d])throw Error("Referenced element not a number");p[d]+=t.na}else if(void 0!==t.si){if("string"!=typeof p)throw Error("Referenced element not a string (it was "+JSON.stringify(p)+")");l[o]=p.slice(0,d)+t.si+p.slice(d)}else if(void 0!==t.sd){if("string"!=typeof p)throw Error("Referenced element not a string");if(p.slice(d,d+t.sd.length)!==t.sd)throw Error("Deleted string does not match");l[o]=p.slice(0,d)+p.slice(d+t.sd.length)}else if(void 0!==t.li&&void 0!==t.ld)u.checkList(p),p[d]=t.li;else if(void 0!==t.li)u.checkList(p),p.splice(d,0,t.li);else if(void 0!==t.ld)u.checkList(p),p.splice(d,1);else if(void 0!==t.lm){if(u.checkList(p),t.lm!=d){var c=p[d];p.splice(d,1),p.splice(t.lm,0,c)}}else if(void 0!==t.oi)u.checkObj(p),p[d]=t.oi;else{if(void 0===t.od)throw Error("invalid / missing instruction in op");u.checkObj(p),delete p[d]}}return n.data},u.incrementalApply=function(e,i,n){for(var r=0;i.length>r;r++){var t=[i[r]];e=u.apply(e,t),n(t,e)}return e};var c=u.pathMatches=function(e,i,n){if(e.length!=i.length)return!1;for(var r=0;e.length>r;r++)if(e[r]!==i[r]&&(!n||r!==e.length-1))return!1;return!0},h=function(e){var i={p:e.p[e.p.length-1]};return null!=e.si?i.i=e.si:i.d=e.sd,i};u.append=function(e,i){i=a(i);var n;if(0!=e.length&&c(i.p,(n=e[e.length-1]).p))null!=n.na&&null!=i.na?e[e.length-1]={p:n.p,na:n.na+i.na}:void 0!==n.li&&void 0===i.li&&i.ld===n.li?void 0!==n.ld?delete n.li:e.pop():void 0!==n.od&&void 0===n.oi&&void 0!==i.oi&&void 0===i.od?n.oi=i.oi:void 0!==n.oi&&void 0!==i.od?void 0!==i.oi?n.oi=i.oi:void 0!==n.od?delete n.oi:e.pop():void 0!==i.lm&&i.p[i.p.length-1]===i.lm||e.push(i);else if(0!=e.length&&c(i.p,n.p,!0))if(null==i.si&&null==i.sd||null==n.si&&null==n.sd)e.push(i);else{var r=[h(n)];if(p._append(r,h(i)),1!==r.length)e.push(i);else{var t=r[0];n.p[n.p.length-1]=t.p,null!=t.i?n.si=t.i:n.sd=t.d}}else e.push(i)},u.compose=function(e,i){u.checkValidOp(e),u.checkValidOp(i);for(var n=a(e),r=0;i.length>r;r++)u.append(n,i[r]);return n},u.normalize=function(e){var i=[];e=s(e)?e:[e];for(var n=0;e.length>n;n++){var r=e[n];null==r.p&&(r.p=[]),u.append(i,r)}return i},u.canOpAffectOp=function(e,i){if(0===e.length)return!0;if(0===i.length)return!1;i=i.slice(0,i.length-1),e=e.slice(0,e.length-1);for(var n=0;e.length>n;n++){var r=e[n];if(n>=i.length||r!=i[n])return!1}return!0},u.transformComponent=function(e,i,n,r){i=a(i),void 0!==i.na&&i.p.push(0),void 0!==n.na&&n.p.push(0);var t;u.canOpAffectOp(n.p,i.p)&&(t=n.p.length-1);var l;u.canOpAffectOp(i.p,n.p)&&(l=i.p.length-1);var o=i.p.length,d=n.p.length;if(void 0!==i.na&&i.p.pop(),void 0!==n.na&&n.p.pop(),n.na){if(null!=l&&d>=o&&n.p[l]==i.p[l])if(void 0!==i.ld){var f=a(n);f.p=f.p.slice(o),i.ld=u.apply(a(i.ld),[f])}else if(void 0!==i.od){var f=a(n);f.p=f.p.slice(o),i.od=u.apply(a(i.od),[f])}return u.append(e,i),e}if(null!=l&&d>o&&i.p[l]==n.p[l])if(void 0!==i.ld){var f=a(n);f.p=f.p.slice(o),i.ld=u.apply(a(i.ld),[f])}else if(void 0!==i.od){var f=a(n);f.p=f.p.slice(o),i.od=u.apply(a(i.od),[f])}if(null!=t){var s=o==d;if(void 0!==n.na);else if(void 0!==n.si||void 0!==n.sd){if(void 0!==i.si||void 0!==i.sd){if(!s)throw Error("must be a string?");var c=h(i),v=h(n),g=[];p._tc(g,c,v,r);for(var m=0;g.length>m;m++){var y=g[m],w={p:i.p.slice(0,t)};w.p.push(y.p),null!=y.i&&(w.si=y.i),null!=y.d&&(w.sd=y.d),u.append(e,w)}return e}}else if(void 0!==n.li&&void 0!==n.ld){if(n.p[t]===i.p[t]){if(!s)return e;if(void 0!==i.ld){if(void 0===i.li||"left"!==r)return e;i.ld=a(n.li)}}}else if(void 0!==n.li)void 0!==i.li&&void 0===i.ld&&s&&i.p[t]===n.p[t]?"right"===r&&i.p[t]++:n.p[t]<=i.p[t]&&i.p[t]++,void 0!==i.lm&&s&&n.p[t]<=i.lm&&i.lm++;else if(void 0!==n.ld){if(void 0!==i.lm&&s){if(n.p[t]===i.p[t])return e;var O=n.p[t],b=i.p[t],k=i.lm;(k>O||O===k&&k>b)&&i.lm--}if(n.p[t]<i.p[t])i.p[t]--;else if(n.p[t]===i.p[t]){if(o>d)return e;if(void 0!==i.ld){if(void 0===i.li)return e;delete i.ld}}}else if(void 0!==n.lm)if(void 0!==i.lm&&o===d){var b=i.p[t],k=i.lm,E=n.p[t],x=n.lm;if(E!==x)if(b===E){if("left"!==r)return e;i.p[t]=x,b===k&&(i.lm=x)}else b>E&&i.p[t]--,b>x?i.p[t]++:b===x&&E>x&&(i.p[t]++,b===k&&i.lm++),k>E?i.lm--:k===E&&k>b&&i.lm--,k>x?i.lm++:k===x&&(x>E&&k>b||E>x&&b>k?"right"===r&&i.lm++:k>b?i.lm++:k===E&&i.lm--)}else if(void 0!==i.li&&void 0===i.ld&&s){var b=n.p[t],k=n.lm;O=i.p[t],O>b&&i.p[t]--,O>k&&i.p[t]++}else{var b=n.p[t],k=n.lm;O=i.p[t],O===b?i.p[t]=k:(O>b&&i.p[t]--,O>k?i.p[t]++:O===k&&b>k&&i.p[t]++)}else if(void 0!==n.oi&&void 0!==n.od){if(i.p[t]===n.p[t]){if(void 0===i.oi||!s)return e;if("right"===r)return e;i.od=n.oi}}else if(void 0!==n.oi){if(void 0!==i.oi&&i.p[t]===n.p[t]){if("left"!==r)return e;u.append(e,{p:i.p,od:n.oi})}}else if(void 0!==n.od&&i.p[t]==n.p[t]){if(!s)return e;if(void 0===i.oi)return e;delete i.od}}return u.append(e,i),e},"undefined"!=typeof brequire?brequire("./helpers")._bootstrapTransform(u,u.transformComponent,u.checkValidOp,u.append):i._bootstrapTransform(u,u.transformComponent,u.checkValidOp,u.append),e.exports=u;var v=window.ottypes=window.ottypes||{},g=e.exports;v[g.name]=g,g.uri&&(v[g.uri]=g)})();// JSON document API for the 'json0' type.

(function() {
  var __slice = [].slice;
  var _types = typeof brequire !== 'undefined' ? brequire('ottypes') : window.ottypes;
  var _type = _types['http://sharejs.org/types/JSONv0'];

  // Helpers

  function depath(path) {
    if (path.length === 1 && path[0].constructor === Array) {
      return path[0];
    } else {
      return path;
    }
  }

  function traverse(snapshot, path) {
    var key = 'data';
    var elem = { data: snapshot };

    for (var i = 0; i < path.length; i++) {
      elem = elem[key];
      key = path[i];
      if (typeof elem === 'undefined') {
        throw new Error('bad path');
      }
    }

    return {
      elem: elem,
      key: key
    };
  }

  function pathEquals(p1, p2) {
    if (p1.length !== p2.length) {
      return false;
    }
    for (var i = 0; i < p1.length; ++i) {
      if (p1[i] !== p2[i]) {
        return false;
      }
    }
    return true;
  }

  function containsPath(p1, p2) {
    if (p1.length < p2.length) return false;
    return pathEquals( p1.slice(0,p2.length), p2);
  }

  // does nothing, used as a default callback
  function nullFunction() {}

  // given a path represented as an array or a number, normalize to an array
  // whole numbers are converted to integers.
  function normalizePath(path) {
    if (path instanceof Array) {
      return path;
    }
    if (typeof(path) == "number") {
      return [path];
    }
    // if (typeof(path) == "string") {
    //   path = path.split(".");
    //   var out = [];
    //   for (var i=0; i<path.length; i++) {
    //     var part = path[i];
    //     if (String(parseInt(part, 10)) == part) {
    //       out.push(parseInt(part, 10));
    //     } else {
    //       out.push(part);
    //     }
    //   }
    //   return out;
    // }
  }

  // helper for creating functions with the method signature func([path],arg1,arg2,...,[cb])
  // populates an array of arguments with a default path and callback
  function normalizeArgs(obj, args, func, brequiredArgsCount){
    args = Array.prototype.slice.call(args);
    var path_prefix = obj.path || [];

    if (func.length > 1 && typeof args[args.length-1] !== 'function') {
      args.push(nullFunction);
    }

    if (args.length < (brequiredArgsCount || func.length)) {
      args.unshift(path_prefix);
    } else {
      args[0] = path_prefix.concat(normalizePath(args[0]));
    }

    return func.apply(obj,args);
  }


  // SubDoc
  // this object is returned from context.createContextAt()

  var SubDoc = function(context, path) {
    this.context = context;
    this.path = path || [];
  };

  SubDoc.prototype._updatePath = function(op){
    console.log("UPDATEPATH", op);
    for (var i = 0; i < op.length; i++) {
      var c = op[i];
      if(c.lm !== undefined && containsPath(this.path,c.p)){
        var new_path_prefix = c.p.slice(0,c.p.length-1);
        new_path_prefix.push(c.lm);
        this.path = new_path_prefix.concat(this.path.slice(new_path_prefix.length));
      }
    }
  };

  SubDoc.prototype.createContextAt = function() {
    var path = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return this.context.createContextAt(this.path.concat(depath(path)));
  };

  SubDoc.prototype.get = function(path) {
    return normalizeArgs(this, arguments, function(path){
      return this.context.get(path);
    });
  };

  SubDoc.prototype.set = function(path, value, cb) {
    return normalizeArgs(this, arguments, function(path, value, cb){
      return this.context.set(path, value, cb);
    });
  };

  SubDoc.prototype.insert = function(path, value, cb) {
    return normalizeArgs(this, arguments, function(path, value, cb){
      return this.context.insert(path, value, cb);
    });
  };

  SubDoc.prototype.remove = function(path, len, cb) {
    return normalizeArgs(this, arguments, function(path, len, cb) {
      return this.context.remove(path, len, cb);
    }, 2);
  };

  SubDoc.prototype.push = function(path, value, cb) {
    return normalizeArgs(this, arguments, function(path, value, cb) {
        var _ref = traverse(this.context.getSnapshot(), path);
        var len = _ref.elem[_ref.key].length;
        path.push(len);
      return this.context.insert(path, value, cb);
    });
  };

  SubDoc.prototype.move = function(path, from, to, cb) {
    return normalizeArgs(this, arguments, function(path, from, to, cb) {
      console.log("sd MOVE");
      return this.context.move(path, from, to, cb);
    });
  };

  SubDoc.prototype.add = function(path, amount, cb) {
    return normalizeArgs(this, arguments, function(path, amount, cb) {
      return this.context.add(path, amount, cb);
    });
  };

  SubDoc.prototype.on = function(event, cb) {
    return this.context.addListener(this.path, event, cb);
  };

  SubDoc.prototype.removeListener = function(l) {
    return this.context.removeListener(l);
  };

  SubDoc.prototype.getLength = function(path) {
    return normalizeArgs(this, arguments, function(path) {
      return this.context.getLength(path);
    });
  };

  // DEPRECATED
  SubDoc.prototype.getText = function(path) {
    return normalizeArgs(this, arguments, function(path) {
      return this.context.getText(path);
    });
  };

  // DEPRECATED
  SubDoc.prototype.deleteText = function(path, pos, length, cb) {
    return normalizeArgs(this, arguments, function(path, pos, length, cb) {
      return this.context.deleteText(path, length, pos, cb);
    });
  };

  SubDoc.prototype.destroy = function() {
    this.context._removeSubDoc(this);
  };


  // JSON API methods
  // these methods are mixed in to the context return from doc.createContext()

  _type.api = {

    provides: {
      json: true
    },

    _fixComponentPaths: function(c) {
      if (!this._listeners) {
        return;
      }
      if (c.na !== undefined || c.si !== undefined || c.sd !== undefined) {
        return;
      }

      var to_remove = [];
      var _ref = this._listeners;

      for (var i = 0; i < _ref.length; i++) {
        var l = _ref[i];
        var dummy = {
          p: l.path,
          na: 0
        };
        var xformed = _type.transformComponent([], dummy, c, 'left');
        if (xformed.length === 0) {
          to_remove.push(i);
        } else if (xformed.length === 1) {
          l.path = xformed[0].p;
        } else {
          throw new Error("Bad assumption in json-api: xforming an 'na' op will always result in 0 or 1 components.");
        }
      }

      to_remove.sort(function(a, b) {
        return b - a;
      });

      var _results = [];
      for (var j = 0; j < to_remove.length; j++) {
        i = to_remove[j];
        _results.push(this._listeners.splice(i, 1));
      }

      return _results;
    },

    _fixPaths: function(op) {
      var _results = [];
      for (var i = 0; i < op.length; i++) {
        var c = op[i];
        _results.push(this._fixComponentPaths(c));
      }
      return _results;
    },

    _submit: function(op, callback) {
      this._fixPaths(op);
      return this.submitOp(op, callback);
    },

    _addSubDoc: function(subdoc){
      this._subdocs || (this._subdocs = []);
      this._subdocs.push(subdoc);
    },

    _removeSubDoc: function(subdoc){
      this._subdocs || (this._subdocs = []);
      for(var i = 0; i < this._subdocs.length; i++){
        if(this._subdocs[i] === subdoc) this._subdocs.splice(i,1);
        return;
      }
    },

    _updateSubdocPaths: function(op){
      this._subdocs || (this._subdocs = []);
      for(var i = 0; i < this._subdocs.length; i++){
        this._subdocs[i]._updatePath(op);
      }
    },

    createContextAt: function() {
      var path = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      var subdoc =  new SubDoc(this, depath(path));
      this._addSubDoc(subdoc);
      return subdoc;
    },

    get: function(path) {
      if (!path) return this.getSnapshot();  
      return normalizeArgs(this,arguments,function(path){
        var _ref = traverse(this.getSnapshot(), path);
        return _ref.elem[_ref.key];
      });
    },

    set: function(path, value, cb) {
      return normalizeArgs(this, arguments, function(path, value, cb) {
        var _ref = traverse(this.getSnapshot(), path);
        var elem = _ref.elem;
        var key = _ref.key;
        var op = {
          p: path
        };

        if (elem.constructor === Array) {
          op.li = value;
          if (typeof elem[key] !== 'undefined') {
            op.ld = elem[key];
          }
        } else if (typeof elem === 'object') {
          op.oi = value;
          if (typeof elem[key] !== 'undefined') {
            op.od = elem[key];
          }
        } else {
          throw new Error('bad path');
        }

        return this._submit([op], cb);
      });
    },

    remove: function(path, len, cb) {
      return normalizeArgs(this, arguments, function(path, len, cb) {
        if (!cb && len instanceof Function) {
          cb = len;
          len = null;
        }
        // if there is no len argument, then we are removing a single item from either a list or a hash
        var _ref, elem, op, key;
        if (len === null || len === undefined) {
          _ref = traverse(this.getSnapshot(), path);
          elem = _ref.elem;
          key = _ref.key;
          op = {
            p: path
          };

          if (typeof elem[key] === 'undefined') {
            throw new Error('no element at that path');
          }

          if (elem.constructor === Array) {
            op.ld = elem[key];
          } else if (typeof elem === 'object') {
            op.od = elem[key];
          } else {
            throw new Error('bad path');
          }
          return this._submit([op], cb);
        } else {
          var pos;
          pos = path.pop();
          _ref = traverse(this.getSnapshot(), path);
          elem = _ref.elem;
          key = _ref.key;
          if (typeof elem[key] === 'string') {
            op = {
              p: path.concat(pos),
              sd: _ref.elem[_ref.key].slice(pos, pos + len)
            };
            return this._submit([op], cb);
          } else if (elem[key].constructor === Array) {
            var ops = [];
            for (var i=pos; i<pos+len; i++) {
              ops.push({
                p: path.concat(pos),
                ld: elem[key][i]
              });
            }
            return this._submit(ops, cb);
          } else {
            throw new Error('element at path does not support range');
          }
        }
      }, 2);
    },

    insert: function(path, value, cb) {
      return normalizeArgs(this, arguments, function(path, value, cb) {
        var pos = path.pop();
        var _ref = traverse(this.getSnapshot(), path);
        var elem = _ref.elem;
        var key = _ref.key;
        var op = {
          p: path.concat(pos)
        };

        if (elem[key].constructor === Array) {
          op.li = value;
        } else if (typeof elem[key] === 'string') {
          op.si = value;
        }
        return this._submit([op], cb);
      });
    },

    move: function(path, from, to, cb) {
      return normalizeArgs(this, arguments, function(path, from, to, cb) {
        var self = this;
        var op = [
          {
            p: path.concat(from),
            lm: to
          }
        ];

        return this._submit(op, function(){
          self._updateSubdocPaths(op);
          if(cb) cb.apply(cb, arguments);
        });
      });
    },

    push: function(path, value, cb) {
      return normalizeArgs(this, arguments, function(path, value, cb) {
        var _ref = traverse(this.getSnapshot(), path);
        var len = _ref.elem[_ref.key].length;
        path.push(len);
        return this.insert(path, value, cb);
      });
    },

    add: function(path, amount, cb) {
      return normalizeArgs(this, arguments, function(path, value, cb) {
        var op = [
          {
            p: path,
            na: amount
          }
        ];
        return this._submit(op, cb);
      });
    },

    getLength: function(path) {
        return normalizeArgs(this, arguments, function(path) {
          return this.get(path).length;
        });
    },

    getText: function(path) {
      return normalizeArgs(this, arguments, function(path) {
        console.warn("Deprecated. Use `get()` instead");
        return this.get(path);
      });
    },

    deleteText: function(path, length, pos, cb) {
      return normalizeArgs(this, arguments, function(path, length, pos, cb) {
        console.warn("Deprecated. Use `remove(path, length, cb)` instead");
        var _ref = traverse(this.getSnapshot(), path);
        var op = [
          {
            p: path.concat(pos),
            sd: _ref.elem[_ref.key].slice(pos, pos + length)
          }
        ];

        return this._submit(op, cb);
      });
    },

    addListener: function(path, event, cb) {
      return normalizeArgs(this, arguments, function(path, value, cb) {
        var listener = {
          path: path,
          event: event,
          cb: cb
        };
        this._listeners || (this._listeners = []);
        this._listeners.push(listener);
        return listener;
      });
    },

    removeListener: function(listener) {
      if (!this._listeners) {
        return;
      }
      var i = this._listeners.indexOf(listener);
      if (i < 0) {
        return false;
      }
      this._listeners.splice(i, 1);
      return true;
    },

    _onOp: function(op) {
      for (var i = 0; i < op.length; i++) {
        var c = op[i];
        this._fixComponentPaths(c);

        if(c.lm !== undefined) {
          this._updateSubdocPaths([c]);
        }

        var match_path = c.na === undefined ? c.p.slice(0, c.p.length - 1) : c.p;

        for (var l = 0; l < this._listeners.length; l++) {
          var listener = this._listeners[l];
          var cb = listener.cb;

          if (pathEquals(listener.path, match_path)) {
            switch (listener.event) {
              case 'insert':
                if (c.li !== undefined && c.ld === undefined) {
                  cb(c.p[c.p.length - 1], c.li);
                } else if (c.oi !== undefined && c.od === undefined) {
                  cb(c.p[c.p.length - 1], c.oi);
                } else if (c.si !== undefined) {
                  cb(c.p[c.p.length - 1], c.si);
                }
                break;
              case 'delete':
                if (c.li === undefined && c.ld !== undefined) {
                  cb(c.p[c.p.length - 1], c.ld);
                } else if (c.oi === undefined && c.od !== undefined) {
                  cb(c.p[c.p.length - 1], c.od);
                } else if (c.sd !== undefined) {
                  cb(c.p[c.p.length - 1], c.sd);
                }
                break;
              case 'replace':
                if (c.li !== undefined && c.ld !== undefined) {
                  cb(c.p[c.p.length - 1], c.ld, c.li);
                } else if (c.oi !== undefined && c.od !== undefined) {
                  cb(c.p[c.p.length - 1], c.od, c.oi);
                }
                break;
              case 'move':
                if (c.lm !== undefined) {
                  cb(c.p[c.p.length - 1], c.lm);
                }
                break;
              case 'add':
                if (c.na !== undefined) {
                  cb(c.na);
                }
            }
          } else if (_type.canOpAffectOp(listener.path, match_path)
              && listener.event === 'child op') {
            var child_path = c.p.slice(listener.path.length);
            cb(child_path, c);
          }
        }
      }
    }
  };

}).call(this);
// This file is included at the top of the compiled client JS.

// All the modules will just add stuff to exports, and it'll all get exported.
var exports = window.sharejs = {version: '0.7.0-alpha8'};

// This is a simple rewrite of microevent.js. I've changed the
// function names to be consistent with node.js EventEmitter.
//
// microevent.js is copyright Jerome Etienne, and licensed under the MIT license:
// https://github.com/jeromeetienne/microevent.js

var MicroEvent = function() {};

MicroEvent.prototype.on = function(event, fn) {
  var events = this._events = this._events || {};
  (events[event] = events[event] || []).push(fn);
};

MicroEvent.prototype.removeListener = function(event, fn) {
  var events = this._events = this._events || {};
  var listeners = events[event] = events[event] || [];

  // Sadly, no IE8 support for indexOf.
  var i = 0;
  while (i < listeners.length) {
    if (listeners[i] === fn) {
      listeners[i] = undefined;
    }
    i++;
  }

  // Compact the list when no event handler is actually running.
  setTimeout(function() {
    events[event] = [];
    var fn;
    for (var i = 0; i < listeners.length; i++) {
      // Only add back event handlers which exist.
      if ((fn = listeners[i])) events[event].push(fn);
    }
  }, 0);
};

MicroEvent.prototype.emit = function(event) {
  var events = this._events;
  var args = Array.prototype.splice.call(arguments, 1);

  if (!events || !events[event]) {
    if (event == 'error') {
      if (console) {
        console.error.apply(console, args);
      }
    }
    return;
  }

  var listeners = events[event];
  for (var i = 0; i < listeners.length; i++) {
    if (listeners[i]) {
      listeners[i].apply(this, args);
    }
  }
};

MicroEvent.prototype.once = function(event, fn) {
  var listener, _this = this;
  this.on(event, listener = function() {
    _this.removeListener(event, listener);
    fn.apply(_this, arguments);
  });
};

MicroEvent.mixin = function(obj) {
  var proto = obj.prototype || obj;
  proto.on = MicroEvent.prototype.on;
  proto.removeListener = MicroEvent.prototype.removeListener;
  proto.emit = MicroEvent.prototype.emit;
  proto.once = MicroEvent.prototype.once;
  return obj;
};

if (typeof module !== "undefined") module.exports = MicroEvent;

var types, MicroEvent;

if (typeof brequire !== "undefined") {
  types = brequire('ottypes');
  MicroEvent = brequire('./microevent');
} else {
  types = window.ottypes;
}

/*
 * A Doc is a client's view on a sharejs document.
 *
 * Documents should not be created directly. Create them by calling the
 * document getting functions in connection.
 *
 * Documents are event emitters. Use doc.on(eventname, fn) to subscribe.
 *
 * Documents currently get mixed in with their type's API methods. So, you can
 * .insert('foo', 0) into a text document and stuff like that.
 *
 * Events:
 * - before op (op, localSite): Fired before an operation is applied to the
 *   document.
 * - op (op, localSite): Fired right after an operation (or part of an
 *   operation) has been applied to the document. Submitting another op here is
 *   invalid - wait until 'after op' if you want to submit more operations.  -
 *   changed (op)
 * - after op (op, localSite): Fired after an operation has been applied. You
 *   can submit more ops here.
 * - subscribed (error): The document was subscribed
 * - unsubscribed (error): The document was unsubscribed
 * - created: The document was created. That means its type was set and it has
 *   some initial data.
 * - error
 */
var Doc = exports.Doc = function(connection, collection, name) {
  this.connection = connection;

  this.collection = collection;
  this.name = name;

  this.version = this.type = null;

  // **** State in document:
 
  // Action. This is either null, or one of the actions (subscribe,
  // unsubscribe, fetch, submit). Only one action can be happening at a time to
  // prevent me from going mad.
  //
  // Possible values:
  // - subscribe
  // - unsubscribe
  // - fetch
  // - submit
  this.action = null;
 
  // The data the document object stores can be in one of the following three states:
  //   - No data. (null) We honestly don't know whats going on.
  //   - Floating ('floating'): we have a locally created document that hasn't
  //     been created on the server yet)
  //   - Live ('ready') (we have data thats current on the server at some version).
  this.state = null;

  // Our subscription status. Either we're subscribed on the server, or we aren't.
  this.subscribed = false;
  // Either we want to be subscribed (true), we want a new snapshot from the
  // server ('fetch'), or we don't care (false).  This is also used when we
  // disconnect & reconnect to decide what to do.
  this.wantSubscribe = false;
  // This list is used for subscribe and unsubscribe, since we'll only want to
  // do one thing at a time.
  this._subscribeCallbacks = [];


  // *** end state stuff.

  // This doesn't provide any standard API access right now.
  this.provides = {};

  // The editing contexts. These are usually instances of the type API when the
  // document is ready for edits.
  this.editingContexts = [];
  
  // The op that is currently roundtripping to the server, or null.
  //
  // When the connection reconnects, the inflight op is resubmitted.
  //
  // This has the same format as an entry in pendingData, which is:
  // {[create:{...}], [del:true], [op:...], callbacks:[...], src:, seq:}
  this.inflightData = null;

  // All ops that are waiting for the server to acknowledge @inflightData
  // This used to just be a single operation, but creates & deletes can't be composed with
  // regular operations.
  //
  // This is a list of {[create:{...}], [del:true], [op:...], callbacks:[...]}
  this.pendingData = [];
};

MicroEvent.mixin(Doc);

Doc.prototype.destroy = function(callback) {
  var doc = this;
  this.unsubscribe(function() {
    // Don't care if there's an error unsubscribing.

    setTimeout(function() {
      // There'll probably be nothing here seeing as how we just unsubscribed.
      for (var i = 0; i < doc._subscribeCallbacks.length; i++) {
        doc._subscribeCallbacks[i]('Document destroyed');
      }
      doc._subscribeCallbacks.length = 0;
    }, 0);

    doc.connection._destroyDoc(doc);
    doc.removeContexts();
    if (callback) callback();
  });
};


// ****** Manipulating the document snapshot, version and type.

// Set the document's type, and associated properties. Most of the logic in
// this function exists to update the document based on any added & removed API
// methods.
Doc.prototype._setType = function(newType) {
  if (typeof newType === 'string') {
    if (!types[newType]) throw new Error("Missing type " + newType);
    newType = types[newType];
  }
  this.removeContexts();

  // Set the new type
  this.type = newType;

  // If we removed the type from the object, also remove its snapshot.
  if (!newType) {
    this.provides = {};
  } else if (newType.api) {
    // Register the new type's API.
    this.provides = newType.api.provides;
  }
};

// Injest snapshot data. This data must include a version, snapshot and type.
// This is used both to injest data that was exported with a webpage and data
// that was received from the server during a fetch.
Doc.prototype.injestData = function(data) {
  if (this.state) {
    if (typeof console !== "undefined") console.warn('Ignoring attempt to injest data in state', this.state);
    return;
  }
  if (typeof data.v !== 'number') throw new Error('Missing version in injested data');


  this.version = data.v;
  // data.data is what the server will actually send. data.snapshot is the old
  // field name - supported now for backwards compatibility.
  this.snapshot = data.data || data.snapshot;
  this._setType(data.type);

  this.state = 'ready';
  this.emit('ready');
};

// Get and return the current document snapshot.
Doc.prototype.getSnapshot = function() {
  return this.snapshot;
};

// The callback will be called at a time when the document has a snapshot and
// you can start applying operations. This may be immediately.
Doc.prototype.whenReady = function(fn) {
  if (this.state === 'ready') {
    fn();
  } else {
    this.on('ready', fn);
  }
};

Doc.prototype.hasPending = function() {
  return this.inflightData != null || !!this.pendingData.length;
};


// **** Helpers for network messages

// Send a message to the connection from this document.
Doc.prototype._send = function(message) {
  message.c = this.collection;
  message.d = this.name;
  this.connection.send(message);
};

// This function exists so connection can call it directly for bulk subscribes.
// It could just make a temporary object literal, thats pretty slow.
Doc.prototype._handleSubscribe = function(err, data) {
  if (err && err !== 'Already subscribed') {
    if (console) console.error("Could not subscribe: " + err);
    this.emit('error', err);
    // There's probably a reason we couldn't subscribe. Don't retry.
    this._setWantSubscribe(false, null, err)
  } else {
    if (data) this.injestData(data);
    this.subscribed = true;
    this.emit('subscribe');
    this._finishSub(true);
  }

  this._clearAction('subscribe');
};

// This is called by the connection when it receives a message for the document.
Doc.prototype._onMessage = function(msg) {
  if (!(msg.c === this.collection && msg.d === this.name)) {
    // This should never happen - its a sanity check for bugs in the connection code.
    throw new Error("Got message for wrong document.");
  }

  // msg.a = the action.
  switch (msg.a) {
    case 'fetch':
      // We're done fetching. This message has no other information.
      if (msg.data) this.injestData(msg.data);
      this._finishSub('fetch', msg.error);
      if (this.wantSubscribe === 'fetch') this.wantSubscribe = false;
      this._clearAction('fetch');
      break;

    case 'sub':
      // Subscribe reply.
      this._handleSubscribe(msg.error, msg.data);
      break;

    case 'unsub':
      // Unsubscribe reply
      this.subscribed = false;
      this.emit('unsubscribe');

      this._finishSub(false, msg.error);
      this._clearAction('unsubscribe');
      break;

    case 'ack':
      // Acknowledge a locally submitted operation.
      //
      // Usually we do nothing here - all the interesting logic happens when we
      // get sent our op back in the op stream (which happens even if we aren't
      // subscribed). However, if the op doesn't get accepted, we still need to
      // clear some state.
      //
      // If the message error is 'Op already submitted', that means we've
      // resent an op that the server already got. It will also be confirmed
      // normally.
      if (msg.error && msg.error !== 'Op already submitted') {
        // The server has rejected an op from the client for some reason.
        // We'll send the error message to the user and try to roll back the change.
        if (this.inflightData) {
          console.warn('Operation was rejected (' + msg.error + '). Trying to rollback change locally.');
          this._tryRollback(this.inflightData);
        } else {
          // I managed to get into this state once. I'm not sure how it happened.
          // The op was maybe double-acknowledged?
          if (console) console.warn('Second acknowledgement message (error) received', msg, this);
        }
          
        this._clearInflightOp(msg.error);
      }
      break;

    case 'op':
      if (this.inflightData &&
          msg.src === this.inflightData.src &&
          msg.seq === this.inflightData.seq) {
        // This one is mine. Accept it as acknowledged.
        this._opAcknowledged(msg);
        break;
      }

      if (msg.v !== this.version) {
        // This will happen naturally in the following (or similar) cases:
        //
        // Client is not subscribed to document.
        // -> client submits an operation (v=10)
        // -> client subscribes to a query which matches this document. Says we
        //    have v=10 of the doc.
        //
        // <- server acknowledges the operation (v=11). Server acknowledges the
        //    operation because the doc isn't subscribed
        // <- server processes the query, which says the client only has v=10.
        //    Server subscribes at v=10 not v=11, so we get another copy of the
        //    v=10 operation.
        //
        // In this case, we can safely ignore the old (duplicate) operation.
        break;
      }

      if (this.inflightData) xf(this.inflightData, msg);

      for (var i = 0; i < this.pendingData.length; i++) {
        xf(this.pendingData[i], msg);
      }

      this.version++;
      this._otApply(msg, false);
      this._afterOtApply(msg, false);
      //console.log('applied', JSON.stringify(msg));
      break;

    case 'meta':
      if (console) console.warn('Unhandled meta op:', msg);
      break;

    default:
      if (console) console.warn('Unhandled document message:', msg);
      break;
  }
};

// Called whenever (you guessed it!) the connection state changes. This will
// happen when we get disconnected & reconnect.
Doc.prototype._onConnectionStateChanged = function(state, reason) {
  if (state === 'connecting') {
    if (this.inflightData) {
      this._sendOpData();
    } else {
      this.flush();
    }
  } else if (state === 'connected') {
    // We go into the connected state once we have a sessionID. We can't send
    // new ops until then, so we need to flush again.
    this.flush();
  } else if (state === 'disconnected') {
    this.action = null;
    this.subscribed = false;
    if (this.subscribed) this.emit('unsubscribed');
  }
};




// ****** Dealing with actions

Doc.prototype._clearAction = function(expectedAction) {
  if (this.action !== expectedAction) {
    console.warn('Unexpected action ' + this.action + ' expected: ' + expectedAction);
  }
  this.action = null;
  this.flush();
};



// Send the next pending op to the server, if we can.
//
// Only one operation can be in-flight at a time. If an operation is already on
// its way, or we're not currently connected, this method does nothing.
Doc.prototype.flush = function() {
  if (!this.connection.canSend || this.action) return;

  var opData;
  // Pump and dump any no-ops from the front of the pending op list.
  while (this.pendingData.length && isNoOp(opData = this.pendingData[0])) {
    var callbacks = opData.callbacks;
    for (var i = 0; i < callbacks.length; i++) {
      callbacks[i](opData.error);
    }
    this.pendingData.shift();
  }

  // First consider changing state
  if (this.subscribed && !this.wantSubscribe) {
    this.action = 'unsubscribe';
    this._send({a:'unsub'});
  } else if (!this.subscribed && this.wantSubscribe === 'fetch') {
    this.action = 'fetch';
    this._send(this.state === 'ready' ? {a:'fetch', v:this.version} : {a:'fetch'});
  } else if (!this.subscribed && this.wantSubscribe) {
    this.action = 'subscribe';
    // Special send method needed for bulk subscribes on reconnect.
    this.connection.sendSubscribe(this.collection, this.name, this.state === 'ready' ? this.version : null);
  } else if (!this.paused && this.pendingData.length && this.connection.state === 'connected') {
    // Try and send any pending ops. We can't send ops while in 
    this.inflightData = this.pendingData.shift();

    // Delay for debugging.
    //var that = this;
    //setTimeout(function() { that._sendOpData(); }, 1000);

    // This also sets action to 'submit'.
    this._sendOpData();
  }
};


// ****** Subscribing, unsubscribing and fetching

// These functions iare copied into the query class as well, so be careful making
// changes here.

// Value is true, false or 'fetch'.
Doc.prototype._setWantSubscribe = function(value, callback, err) {
  if (this.subscribed === this.wantSubscribe &&
      (this.subscribed === value || value === 'fetch' && this.subscribed)) {
    if (callback) callback(err);
    return;
  }
  
  if (!this.wantSubscribe !== !value) {
    // Call all the current subscribe/unsubscribe callbacks.
    for (var i = 0; i < this._subscribeCallbacks.length; i++) {
      // Should I return an error here? What happened is the user unsubcribed
      // with a callback then resubscribed straight after. Does that mean the
      // unsubscribe failed?
      this._subscribeCallbacks[i](err);
    }
    this._subscribeCallbacks.length = 0;
  }

  // If we want to subscribe, don't weaken it to a fetch.
  if (value !== 'fetch' || this.wantSubscribe !== true)
    this.wantSubscribe = value;

  if (callback) this._subscribeCallbacks.push(callback);
  this.flush();
};

// Open the document. There is no callback and no error handling if you're
// already connected.
//
// Only call this once per document.
Doc.prototype.subscribe = function(callback) {
  this._setWantSubscribe(true, callback);
};

// Unsubscribe. The data will stay around in local memory, but we'll stop
// receiving updates.
Doc.prototype.unsubscribe = function(callback) {
  this._setWantSubscribe(false, callback);
};

// Call to request fresh data from the server.
Doc.prototype.fetch = function(callback) {
  this._setWantSubscribe('fetch', callback);
};

// Called when our subscribe, fetch or unsubscribe messages are acknowledged.
Doc.prototype._finishSub = function(value, error) {
  if (value === this.wantSubscribe) {
    for (var i = 0; i < this._subscribeCallbacks.length; i++) {
      this._subscribeCallbacks[i](error);
    }
    this._subscribeCallbacks.length = 0;
  }
};


// Operations


// ************ Dealing with operations.

// Helper function to set opData to contain a no-op.
var setNoOp = function(opData) {
  delete opData.op;
  delete opData.create;
  delete opData.del;
};

var isNoOp = function(opData) {
  return !opData.op && !opData.create && !opData.del;
}

// Try to compose data2 into data1. Returns truthy if it succeeds, otherwise falsy.
var tryCompose = function(type, data1, data2) {
  if (data1.create && data2.del) {
    setNoOp(data1);
  } else if (data1.create && data2.op) {
    // Compose the data into the create data.
    var data = (data1.create.data === undefined) ? type.create() : data1.create.data;
    data1.create.data = type.apply(data, data2.op);
  } else if (isNoOp(data1)) {
    data1.create = data2.create;
    data1.del = data2.del;
    data1.op = data2.op;
  } else if (data1.op && data2.op && type.compose) {
    data1.op = type.compose(data1.op, data2.op);
  } else {
    return false;
  }
  return true;
};

// Transform server op data by a client op, and vice versa. Ops are edited in place.
var xf = function(client, server) {
  // In this case, we're in for some fun. There are some local operations
  // which are totally invalid - either the client continued editing a
  // document that someone else deleted or a document was created both on the
  // client and on the server. In either case, the local document is way
  // invalid and the client's ops are useless.
  //
  // The client becomes a no-op, and we keep the server op entirely.
  if (server.create || server.del) return setNoOp(client);
  if (client.create) throw new Error('Invalid state. This is a bug.');

  // The client has deleted the document while the server edited it. Kill the
  // server's op.
  if (client.del) return setNoOp(server);

  // We only get here if either the server or client ops are no-op. Carry on,
  // nothing to see here.
  if (!server.op || !client.op) return;

  // They both edited the document. This is the normal case for this function -
  // as in, most of the time we'll end up down here.
  //
  // You should be wondering why I'm using client.type instead of this.type.
  // The reason is, if we get ops at an old version of the document, this.type
  // might be undefined or a totally different type. By pinning the type to the
  // op data, we make sure the right type has its transform function called.
  if (client.type.transformX) {
    var result = client.type.transformX(client.op, server.op);
    client.op = result[0];
    server.op = result[1];
  } else {
    //console.log('xf', JSON.stringify(client.op), JSON.stringify(server.op));
    var _c = client.type.transform(client.op, server.op, 'left');
    var _s = client.type.transform(server.op, client.op, 'right');
    client.op = _c; server.op = _s;
    //console.log('->', JSON.stringify(client.op), JSON.stringify(server.op));
  }
};

// Internal method to actually apply the given op data to our local model.
//
// _afterOtApply() should always be called synchronously afterwards.
Doc.prototype._otApply = function(opData, context) {
  // Lock the document. Nobody is allowed to call submitOp() until _afterOtApply is called.
  this.locked = true;

  if (opData.create) {
    // If the type is currently set, it means we tried creating the document
    // and someone else won. client create x server create = server create.
    var create = opData.create;
    this._setType(create.type);
    this.snapshot = this.type.create(create.data);

    // This is a bit heavyweight, but I want the created event to fire outside of the lock.
    this.once('unlock', function() {
      this.emit('create', context);
    });
  } else if (opData.del) {
    // The type should always exist in this case. del x _ = del
    var oldSnapshot = this.snapshot;
    this._setType(null);
    this.once('unlock', function() {
      this.emit('del', context, oldSnapshot);
    });
  } else if (opData.op) {
    if (!this.type) throw new Error('Document does not exist');

    var type = this.type;

    var op = opData.op;
    
    // The context needs to be told we're about to edit, just in case it needs
    // to store any extra data. (text-tp2 has this constraint.)
    for (var i = 0; i < this.editingContexts.length; i++) {
      var c = this.editingContexts[i];
      if (c != context && c._beforeOp) c._beforeOp(opData.op);
    }

    this.emit('before op', op, context);

    // This exists so clients can pull any necessary data out of the snapshot
    // before it gets changed.  Previously we kept the old snapshot object and
    // passed it to the op event handler. However, apply no longer guarantees
    // the old object is still valid.
    //
    // Because this could be totally unnecessary work, its behind a flag. set
    // doc.incremental to enable.
    if (this.incremental && type.incrementalApply) {
      var _this = this;
      type.incrementalApply(this.snapshot, op, function(o, snapshot) {
        _this.snapshot = snapshot;
        _this.emit('op', o, context);
      });
    } else {
      // This is the most common case, simply applying the operation to the local snapshot.
      this.snapshot = type.apply(this.snapshot, op);
      this.emit('op', op, context);
    }
  }
  // Its possible for none of the above cases to match, in which case the op is
  // a no-op. This will happen when a document has been deleted locally and
  // remote ops edit the document.
};

// This should be called right after _otApply.
Doc.prototype._afterOtApply = function(opData, context) {
  this.locked = false;
  this.emit('unlock');
  if (opData.op) {
    var contexts = this.editingContexts;
    // Notify all the contexts about the op (well, all the contexts except
    // the one which initiated the submit in the first place).
    for (var i = 0; i < contexts.length; i++) {
      var c = contexts[i];
      if (c != context && c._onOp) c._onOp(opData.op);
    }
    for (var i = 0; i < contexts.length; i++) {
      if (contexts.remove) contexts.splice(i--, 1);
    }

    return this.emit('after op', opData.op, context);
  }
};



// ***** Sending operations


// Actually send op data to the server.
Doc.prototype._sendOpData = function() {
  var d = this.inflightData;

  if (this.action) throw new Error('invalid state ' + this.action + ' for sendOpData');
  this.action = 'submit';

  var msg = {a:'op', v:this.version};
  if (d.src) {
    msg.src = d.src;
    msg.seq = d.seq;
  }

  // The server autodetects this.
  //if (this.state === 'unsubscribed') msg.f = true; // fetch intermediate ops

  if (d.op) msg.op = d.op;
  if (d.create) msg.create = d.create;
  if (d.del) msg.del = d.del;

  msg.c = this.collection;
  msg.d = this.name;

  this.connection.sendOp(msg);
   
  // The first time we send an op, its id and sequence number is implicit.
  if (!d.src) {
    d.src = this.connection.id;
    d.seq = this.connection.seq++;
  }
};


// Internal method called to do the actual work for submitOp(), create() and del().
//
// context is optional.
Doc.prototype._submitOpData = function(opData, context, callback) {
  //console.log('submit', JSON.stringify(opData), 'v=', this.version);

  if (typeof context === 'function') {
    callback = context;
    context = true; // The default context is true.
  }
  if (context == null) context = true;

  var error = function(err) {
    if (callback) callback(err);
    else if (console) console.warn('Failed attempt to submitOp:', err);
  };

  if (this.locked) {
    return error("Cannot call submitOp from inside an 'op' event handler");
  }

  // The opData contains either op, create, delete, or none of the above (a no-op).

  if (opData.op) {
    if (!this.type) return error('Document has not been created');

    // Try to normalize the op. This removes trailing skip:0's and things like that.
    if (this.type.normalize) opData.op = this.type.normalize(opData.op);
  }

  if (!this.state) {
    this.state = 'floating';
  }

  // Actually apply the operation locally.
  this._otApply(opData, context);

  // If the type supports composes, try to compose the operation onto the end
  // of the last pending operation.
  var entry = this.pendingData[this.pendingData.length - 1];

  if (this.pendingData.length &&
      (entry = this.pendingData[this.pendingData.length - 1],
       tryCompose(this.type, entry, opData))) {
  } else {
    entry = opData;
    opData.type = this.type;
    opData.callbacks = [];
    this.pendingData.push(opData);
  }

  if (callback) entry.callbacks.push(callback);

  this._afterOtApply(opData, context);

  // The call to flush is in a timeout so if submitOp() is called multiple
  // times in a closure all the ops are combined before being sent to the
  // server. It doesn't matter if flush is called a bunch of times.
  var _this = this;
  setTimeout((function() { _this.flush(); }), 0);
};


// *** Client OT entrypoints.

// Submit an operation to the document. The op must be valid given the current OT type.
Doc.prototype.submitOp = function(op, context, callback) {
  this._submitOpData({op: op}, context, callback);
};

// Create the document, which in ShareJS semantics means to set its type. Every
// object implicitly exists in the database but has no data and no type. Create
// sets the type of the object and can optionally set some initial data on the
// object, depending on the type.
Doc.prototype.create = function(type, data, context, callback) {
  if (typeof data === 'function') {
    // Setting the context to be the callback function in this case so _submitOpData
    // can handle the default value thing.
    context = data;
    data = undefined;
  }
  if (this.type) {
    if (callback) callback('Document already exists');
    return 
  }

  this._submitOpData({create: {type:type, data:data}}, context, callback);
};

// Delete the document. This creates and submits a delete operation to the
// server. Deleting resets the object's type to null and deletes its data. The
// document still exists, and still has the version it used to have before you
// deleted it (well, old version +1).
Doc.prototype.del = function(context, callback) {
  if (!this.type) {
    if (callback) callback('Document does not exist');
    return;
  }

  this._submitOpData({del: true}, context, callback);
};


// Pausing stops the document from sending any operations to the server.
Doc.prototype.pause = function() {
  this.paused = true;
};

Doc.prototype.resume = function() {
  this.paused = false;
  this.flush();
};


// *** Receiving operations


// This will be called when the server rejects our operations for some reason.
// There's not much we can do here if the OT type is noninvertable, but that
// shouldn't happen too much in real life because readonly documents should be
// flagged as such. (I should probably figure out a flag for that).
//
// This does NOT get called if our op fails to reach the server for some reason
// - we optimistically assume it'll make it there eventually.
Doc.prototype._tryRollback = function(opData) {
  // This is probably horribly broken.
  if (opData.create) {
    this._setType(null);

    // I don't think its possible to get here if we aren't in a floating state.
    if (this.state === 'floating')
      this.state = null;
    else
      console.warn('Rollback a create from state ' + this.state);

  } else if (opData.op && opData.type.invert) {
    opData.op = opData.type.invert(opData.op);

    // Transform the undo operation by any pending ops.
    for (var i = 0; i < this.pendingData.length; i++) {
      xf(this.pendingData[i], opData);
    }

    // ... and apply it locally, reverting the changes.
    // 
    // This operation is applied to look like it comes from a remote context.
    // I'm still not 100% sure about this functionality, because its really a
    // local op. Basically, the problem is that if the client's op is rejected
    // by the server, the editor window should update to reflect the undo.
    this._otApply(opData, false);
    this._afterOtApply(opData, false);
  } else if (opData.op || opData.del) {
    // This is where an undo stack would come in handy.
    this._setType(null);
    this.version = null;
    this.state = null;
    this.subscribed = false;
    this.emit('error', "Op apply failed and the operation could not be reverted");

    // Trigger a fetch. In our invalid state, we can't really do anything.
    this.fetch();
    this.flush();
  }
};

Doc.prototype._clearInflightOp = function(error) {
  var callbacks = this.inflightData.callbacks;
  for (var i = 0; i < callbacks.length; i++) {
    callbacks[i](error || this.inflightData.error);
  }

  this.inflightData = null;
  this._clearAction('submit');

  if (!this.pendingData.length) {
    // This isn't a very good name.
    this.emit('nothing pending');
  }
};

// This is called when the server acknowledges an operation from the client.
Doc.prototype._opAcknowledged = function(msg) {
  // Our inflight op has been acknowledged, so we can throw away the inflight data.
  // (We were only holding on to it incase we needed to resend the op.)
  if (!this.state) {
    throw new Error('opAcknowledged called from a null state. This should never happen.');
  } else if (this.state === 'floating') {
    if (!this.inflightData.create) throw new Error('Cannot acknowledge an op.');

    // Our create has been acknowledged. This is the same as injesting some data.
    this.version = msg.v;
    this.state = 'ready';
    var _this = this;
    setTimeout(function() { _this.emit('ready'); }, 0);
  } else {
    // We already have a snapshot. The snapshot should be at the acknowledged
    // version, because the server has sent us all the ops that have happened
    // before acknowledging our op.

    // This should never happen - something is out of order.
    if (msg.v !== this.version)
      throw new Error('Invalid version from server. This can happen when you submit ops in a submitOp callback.');
  }
  
  // The op was committed successfully. Increment the version number
  this.version++;

  this._clearInflightOp();
};


// API Contexts

// This creates and returns an editing context using the current OT type.
Doc.prototype.createContext = function() {
  var type = this.type;
  if (!type) throw new Error('Missing type');

  // I could use the prototype chain to do this instead, but Object.create
  // isn't defined on old browsers. This will be fine.
  var doc = this;
  var context = {
    getSnapshot: function() {
      return doc.snapshot;
    },
    submitOp: function(op, callback) {
      doc.submitOp(op, context, callback);
    },
    destroy: function() {
      if (this.detach) {
        this.detach();
        // Don't double-detach.
        delete this.detach;
      }
      // It will be removed from the actual editingContexts list next time
      // we receive an op on the document (and the list is iterated through).
      //
      // This is potentially dodgy, allowing a memory leak if you create &
      // destroy a whole bunch of contexts without receiving or sending any ops
      // to the document.
      delete this._onOp;
      this.remove = true;
    },

    // This is dangerous, but really really useful for debugging. I hope people
    // don't depend on it.
    _doc: this,
  };

  if (type.api) {
    // Copy everything else from the type's API into the editing context.
    for (var k in type.api) {
      context[k] = type.api[k];
    }
  } else {
    context.provides = {};
  }

  this.editingContexts.push(context);

  return context;
};

Doc.prototype.removeContexts = function() {
  for (var i = 0; i < this.editingContexts.length; i++) {
    this.editingContexts[i].destroy();
  }
  this.editingContexts.length = 0;
};

// A Connection wraps a persistant BC connection to a sharejs server.
//
// This class implements the client side of the protocol defined here:
// https://github.com/josephg/ShareJS/wiki/Wire-Protocol
//
// The equivalent server code is in src/server/session.
//
// This file is a bit of a mess. I'm dreadfully sorry about that. It passes all the tests,
// so I have hope that its *correct* even if its not clean.
//
// To make a connection, use:
//  new sharejs.Connection(socket)
//
// The socket should look like a websocket connection. It should have the following properties:
//  send(msg): Send the given message. msg may be an object - if so, you might need to JSON.stringify it.
//  close(): Disconnect the session
//
//  onmessage = function(msg){}: Event handler which is called whenever a message is received. The message
//     passed in should already be an object. (It may need to be JSON.parsed)
//  onclose
//  onerror
//  onopen
//  onconnecting
//
// The socket should probably automatically reconnect. If so, it should emit the appropriate events as it
// disconnects & reconnects. (onclose(), onconnecting(), onopen()).

var types, Doc;
if (typeof brequire !== 'undefined') {
  types = brequire('ottypes');
  Doc = brequire('./doc').Doc;
  Query = brequire('./query').Query;
} else {
  types = window.ottypes;
  Doc = exports.Doc;
}

var Connection = exports.Connection = function (socket) {
  this.socket = socket;

  // Map of collection -> docName -> doc object for created documents.
  // (created documents MUST BE UNIQUE)
  this.collections = {};

  // Each query is created with an id that the server uses when it sends us
  // info about the query (updates, etc).
  //this.nextQueryId = (Math.random() * 1000) |0;
  this.nextQueryId = 1;

  // Map from query ID -> query object.
  this.queries = {};

  // Connection state.
  // 
  // States:
  // - 'connecting': The connection has been established, but we don't have our client ID yet
  // - 'connected': We have connected and recieved our client ID. Ready for data.
  // - 'disconnected': The connection is closed, but it will reconnect automatically.
  // - 'stopped': The connection is closed, and should not reconnect.
  this.state = (socket.readyState === 0 || socket.readyState === 1) ? 'connecting' : 'disconnected';

  // This is a helper variable the document uses to see whether we're currently
  // in a 'live' state. It is true if the state is 'connecting' or 'connected'.
  this.canSend = this.state === 'connecting';

  // Reset some more state variables.
  this.reset();

  this.debug = false;
  // I'll store the most recent 100 messages so when errors occur we can see what happened.
  this.messageBuffer = [];

  var connection = this;

  var handleMessage = function(msg) {
    // Switch on the message action. Most messages are for documents and are
    // handled in the doc class.
    switch (msg.a) {
      case 'init':
        // Client initialization packet. This bundle of joy contains our client
        // ID.
        if (msg.protocol !== 0) throw new Error('Invalid protocol version');
        if (typeof msg.id != 'string') throw new Error('Invalid client id');

        connection.id = msg.id;
        connection._setState('connected');
        break;

      case 'qfetch':
      case 'qsub':
      case 'q':
      case 'qunsub':
        // Query message. Pass this to the appropriate query object.
        var query = connection.queries[msg.id];
        if (query) query._onMessage(msg);
        break;

      case 'bs':
        // Bulk subscribe response. The responses for each document are contained within.
        var result = msg.s;
        for (var cName in result) {
          for (var docName in result[cName]) {
            var doc = connection.get(cName, docName);
            if (!doc) {
              if (console) console.error('Message for unknown doc. Ignoring.', msg);
              break;
            }

            var msg = result[cName][docName];
            if (typeof msg === 'object') {
              doc._handleSubscribe(msg.error, msg.data);
            } else {
              // The msg will be true if we simply resubscribed.
              doc._handleSubscribe(null, null);
            }
          }
        }
        break;

      default:
        // Document message. Pull out the referenced document and forward the
        // message.
        var collection, docName, doc;
        if (msg.d) {
          collection = connection._lastReceivedCollection = msg.c;
          docName = connection._lastReceivedDoc = msg.d;
        } else {
          collection = msg.c = connection._lastReceivedCollection;
          docName = msg.d = connection._lastReceivedDoc;
        }

        doc = connection.get(collection, docName);
        if (!doc) {
          if (console) console.error('Message for unknown doc. Ignoring.', msg);
          break;
        }
        doc._onMessage(msg);
    }
  };

  // Attach event handlers to the socket.
  socket.onmessage = function(msg) {
    if (connection.debug) console.log('RECV', JSON.stringify(msg));
    connection.messageBuffer.push({t:(new Date()).toTimeString(), recv:JSON.stringify(msg)});
    while (connection.messageBuffer.length > 100) {
      connection.messageBuffer.shift();
    }

    try {
      handleMessage(msg);
    } catch (e) {
      connection.emit('error', e);
      // We could also restart the connection here, although that might result
      // in infinite reconnection bugs.
    }
  }

  socket.onopen = function() {
    connection._setState('connecting');
  };

  socket.onerror = function(e) {
    // This isn't the same as a regular error, because it will happen normally
    // from time to time. Your connection should probably automatically
    // reconnect anyway, but that should be triggered off onclose not onerror.
    // (onclose happens when onerror gets called anyway).
    connection.emit('connection error', e);
  };

  socket.onclose = function(reason) {
    connection._setState('disconnected', reason);
    if (reason === 'Closed' || reason === 'Stopped by server') {
      connection._setState('stopped', reason);
    }
  };
}

/* Why does this function exist? Is it important?
Connection.prototype._error = function(e) {
  this._setState('stopped', e);
  return this.disconnect(e);
};
*/

Connection.prototype.reset = function() {
  this.id = this.lastError =
    this._lastReceivedCollection = this._lastReceivedDoc =
    this._lastSentCollection = this._lastSentDoc = null;

  this.seq = 1;
};

// Set the connection's state. The connection is basically a state machine.
Connection.prototype._setState = function(newState, data) {
  if (this.state === newState) return;

  // I made a state diagram. The only invalid transitions are getting to
  // 'connecting' from anywhere other than 'disconnected' and getting to
  // 'connected' from anywhere other than 'connecting'.
  if ((newState === 'connecting' && (this.state !== 'disconnected' && this.state !== 'stopped'))
      || (newState === 'connected' && this.state !== 'connecting')) {
    throw new Error("Cannot transition directly from " + this.state + " to " + newState);
  }

  this.state = newState;
  this.canSend = newState === 'connecting' || newState === 'connected';

  if (newState === 'disconnected') this.reset();

  this.emit(newState, data);

  // & Emit the event to all documents & queries. It might make sense for
  // documents to just register for this stuff using events, but that couples
  // connections and documents a bit much. Its not a big deal either way.
  this.opQueue = [];
  this.subscribeData = {};
  for (var c in this.collections) {
    var collection = this.collections[c];
    for (var docName in collection) {
      collection[docName]._onConnectionStateChanged(newState, data);
    }
  }


  // Its important that operations are resent in the same order that they were
  // originally sent. If we don't sort, an op with a high sequence number will
  // convince the server not to accept any ops with earlier sequence numbers.
  this.opQueue.sort(function(a, b) { return a.seq - b.seq; });
  for (var i = 0; i < this.opQueue.length; i++) {
    this.send(this.opQueue[i]);
  }

  // Only send bulk subscribe if not empty. Its weird using a for loop for
  // this, but it works pretty well.
  for (var __unused in this.subscribeData) { 
    this.send({a:'bs', s:this.subscribeData});
    break;
  }

  this.opQueue = null;
  this.subscribeData = null;
  
  // No bulk subscribe for queries yet.
  for (var id in this.queries) {
    this.queries[id]._onConnectionStateChanged(newState, data);
  }
};

// So, there's an awful error case where the client sends two requests (which
// fail), then reconnects. The documents could have _onConnectionStateChanged
// called in the wrong order and the operations then get sent with reversed
// sequence numbers. This causes the server to incorrectly reject the second
// sent op. So we need to queue the operations while we're reconnecting and
// resend them in the correct order.
Connection.prototype.sendOp = function(data) {
  if (this.opQueue) {
    this.opQueue.push(data);
  } else {
    this.send(data);
  }
};

// This is called by the document class when the document wants to subscribe.
// We could just send a subscribe message, but during reconnect that causes a
// bajillion messages over browserchannel. During reconnect we'll aggregate,
// similar to sendOp.
Connection.prototype.sendSubscribe = function(collection, name, v) {
  if (this.subscribeData) {
    var data = this.subscribeData;
    if (!data[collection]) data[collection] = {};

    data[collection][name] = v || null;
  } else {
    var msg = {a:'sub', c:collection, d:name};
    if (v != null) msg.v = v;
    this.send(msg);
  }
};

// Send a message to the connection.
Connection.prototype.send = function(msg) {
  if (this.debug) console.log("SEND", JSON.stringify(msg));
  this.messageBuffer.push({t:Date.now(), send:JSON.stringify(msg)});
  while (this.messageBuffer.length > 100) {
    this.messageBuffer.shift();
  }

  if (msg.d) { // The document the message refers to. Not set for queries.
    var collection = msg.c;
    var docName = msg.d;
    if (collection === this._lastSentCollection && docName === this._lastSentDoc) {
      delete msg.c;
      delete msg.d;
    } else {
      this._lastSentCollection = collection;
      this._lastSentDoc = docName;
    }
  }

  this.socket.send(msg);
};

Connection.prototype.disconnect = function() {
  // This will call @socket.onclose(), which in turn will emit the 'disconnected' event.
  this.socket.close();
};


// ***** Document management

Connection.prototype.getExisting = function(collection, name) {
  if (this.collections[collection]) return this.collections[collection][name];
};

Connection.prototype.getOrCreate = function(collection, name, data) {
  console.trace('getOrCreate is deprecated. Use get() instead');
  return this.get(collection, name, data);
};

// Create a document if it doesn't exist. Returns the document synchronously.
Connection.prototype.get = function(collection, name, data) {
  var doc = this.getExisting(collection, name);

  if (!doc) {
    // Create it.
    doc = new Doc(this, collection, name);

    var collectionObject = this.collections[collection] =
      (this.collections[collection] || {});
    collectionObject[name] = doc;
  }

  // Even if the document isn't new, its possible the document was created
  // manually and then tried to be re-created with data (suppose a query
  // returns with data for the document). We should hydrate the document
  // immediately if we can because the query callback will expect the document
  // to have data.
  if (data && data.data !== undefined && !doc.state) {
    doc.injestData(data);
  }

  return doc;
};

// Call doc.destroy()
Connection.prototype._destroyDoc = function(doc) {
  var collectionObject = this.collections[doc.collection];
  if (!collectionObject) return;

  delete collectionObject[doc.name];

  // Delete the collection container if its empty. This could be a source of
  // memory leaks if you slowly make a billion collections, which you probably
  // won't do anyway, but whatever.
  if (!hasKeys(collectionObject))
    delete this.collections[doc.collection];
};
 
function hasKeys(object) {
  for (var key in object) return true;
  return false;
};

// **** Queries.

// Helper for createFetchQuery and createSubscribeQuery, below.
Connection.prototype._createQuery = function(type, collection, q, options, callback) {
  if (type !== 'fetch' && type !== 'sub')
    throw new Error('Invalid query type: ' + type);

  if (!options) options = {};
  var id = this.nextQueryId++;
  var query = new Query(type, this, id, collection, q, options, callback);
  this.queries[id] = query;
  query._execute();
  return query;
};

// Internal function. Use query.destroy() to remove queries.
Connection.prototype._destroyQuery = function(query) {
  delete this.queries[query.id];
};

// The query options object can contain the following fields:
//
// docMode: What to do with documents that are in the result set. Can be
//   null/undefined (default), 'fetch' or 'subscribe'. Fetch mode indicates
//   that the server should send document snapshots to the client for all query
//   results. These will be hydrated into the document objects before the query
//   result callbacks are returned. Subscribe mode gets document snapshots and
//   automatically subscribes the client to all results. Note that the
//   documents *WILL NOT* be automatically unsubscribed when the query is
//   destroyed. (ShareJS doesn't have enough information to do that safely).
//   Beware of memory leaks when using this option.
//
// poll: Forcably enable or disable polling mode. Polling mode will reissue the query
//   every time anything in the collection changes (!!) so, its quite
//   expensive.  It is automatically enabled for paginated and sorted queries.
//   By default queries run with polling mode disabled; which will only check
//   changed documents to test if they now match the specified query.
//   Set to false to disable polling mode, or true to enable it. If you don't
//   specify a poll option, polling mode is enabled or disabled automatically
//   by the query's backend.
//
// backend: Set the backend source for the query. You can attach different
//   query backends to livedb and pick which one the query should hit using
//   this parameter.
//
// results: (experimental) Initial list of resultant documents. This is
//   useful for rehydrating queries when you're using autoFetch / autoSubscribe
//   so the server doesn't have to send over snapshots for documents the client
//   already knows about. This is experimental - the API may change in upcoming
//   versions.

// Create a fetch query. Fetch queries are only issued once, returning the
// results directly into the callback.
//
// The index is specific to the source, but if you're using mongodb it'll be
// the collection to which the query is made.
// The callback should have the signature function(error, results, extraData)
// where results is a list of Doc objects.
Connection.prototype.createFetchQuery = function(index, q, options, callback) {
  return this._createQuery('fetch', index, q, options, callback);
};

// Create a subscribe query. Subscribe queries return with the initial data
// through the callback, then update themselves whenever the query result set
// changes via their own event emitter.
//
// If present, the callback should have the signature function(error, results, extraData)
// where results is a list of Doc objects.
Connection.prototype.createSubscribeQuery = function(index, q, options, callback) {
  return this._createQuery('sub', index, q, options, callback);
};

if (typeof brequire !== 'undefined') {
  MicroEvent = brequire('./microevent');
}

MicroEvent.mixin(Connection);

/* This contains the textarea binding for ShareJS. This binding is really
 * simple, and a bit slow on big documents (Its O(N). However, it brequires no
 * changes to the DOM and no heavy libraries like ace. It works for any kind of
 * text input field.
 *
 * You probably want to use this binding for small fields on forms and such.
 * For code editors or rich text editors or whatever, I recommend something
 * heavier.
 */


/* applyChange creates the edits to convert oldval -> newval.
 *
 * This function should be called every time the text element is changed.
 * Because changes are always localised, the diffing is quite easy. We simply
 * scan in from the start and scan in from the end to isolate the edited range,
 * then delete everything that was removed & add everything that was added.
 * This wouldn't work for complex changes, but this function should be called
 * on keystroke - so the edits will mostly just be single character changes.
 * Sometimes they'll paste text over other text, but even then the diff
 * generated by this algorithm is correct.
 *
 * This algorithm is O(N). I suspect you could speed it up somehow using regular expressions.
 */
var applyChange = function(ctx, oldval, newval) {
  // Strings are immutable and have reference equality. I think this test is O(1), so its worth doing.
  if (oldval === newval) return;

  var commonStart = 0;
  while (oldval.charAt(commonStart) === newval.charAt(commonStart)) {
    commonStart++;
  }

  var commonEnd = 0;
  while (oldval.charAt(oldval.length - 1 - commonEnd) === newval.charAt(newval.length - 1 - commonEnd) &&
      commonEnd + commonStart < oldval.length && commonEnd + commonStart < newval.length) {
    commonEnd++;
  }

  if (oldval.length !== commonStart + commonEnd) {
    ctx.remove(commonStart, oldval.length - commonStart - commonEnd);
  }
  if (newval.length !== commonStart + commonEnd) {
    ctx.insert(commonStart, newval.slice(commonStart, newval.length - commonEnd));
  }
};

// Attach a textarea to a document's editing context.
//
// The context is optional, and will be created from the document if its not
// specified.
window.sharejs.Doc.prototype.attachTextarea = function(elem, ctx) {
  if (!ctx) ctx = this.createContext();

  if (!ctx.provides.text) throw new Error('Cannot attach to non-text document');

  elem.value = ctx.get();

  // The current value of the element's text is stored so we can quickly check
  // if its been changed in the event handlers. This is mostly for browsers on
  // windows, where the content contains \r\n newlines. applyChange() is only
  // called after the \r\n newlines are converted, and that check is quite
  // slow. So we also cache the string before conversion so we can do a quick
  // check incase the conversion isn't needed.
  var prevvalue;

  // Replace the content of the text area with newText, and transform the
  // current cursor by the specified function.
  var replaceText = function(newText, transformCursor) {
    if (transformCursor) {
      var newSelection = [transformCursor(elem.selectionStart), transformCursor(elem.selectionEnd)];
    }

    // Fixate the window's scroll while we set the element's value. Otherwise
    // the browser scrolls to the element.
    var scrollTop = elem.scrollTop;
    elem.value = newText;
    prevvalue = elem.value; // Not done on one line so the browser can do newline conversion.
    if (elem.scrollTop !== scrollTop) elem.scrollTop = scrollTop;

    // Setting the selection moves the cursor. We'll just have to let your
    // cursor drift if the element isn't active, though usually users don't
    // care.
    if (newSelection && window.document.activeElement === elem) {
      elem.selectionStart = newSelection[0];
      elem.selectionEnd = newSelection[1];
    }
  };

  replaceText(ctx.get());


  // *** remote -> local changes

  ctx.onInsert = function(pos, text) {
    var transformCursor = function(cursor) {
      return pos < cursor ? cursor + text.length : cursor;
    };

    // Remove any window-style newline characters. Windows inserts these, and
    // they mess up the generated diff.
    var prev = elem.value.replace(/\r\n/g, '\n');
    replaceText(prev.slice(0, pos) + text + prev.slice(pos), transformCursor);
  };

  ctx.onRemove = function(pos, length) {
    var transformCursor = function(cursor) {
      // If the cursor is inside the deleted region, we only want to move back to the start
      // of the region. Hence the Math.min.
      return pos < cursor ? cursor - Math.min(length, cursor - pos) : cursor;
    };

    var prev = elem.value.replace(/\r\n/g, '\n');
    replaceText(prev.slice(0, pos) + prev.slice(pos + length), transformCursor);
  };


  // *** local -> remote changes

  // This function generates operations from the changed content in the textarea.
  var genOp = function(event) {
    // In a timeout so the browser has time to propogate the event's changes to the DOM.
    setTimeout(function() {
      if (elem.value !== prevvalue) {
        prevvalue = elem.value;
        applyChange(ctx, ctx.get(), elem.value.replace(/\r\n/g, '\n'));
      }
    }, 0);
  };

  var eventNames = ['textInput', 'keydown', 'keyup', 'select', 'cut', 'paste'];
  for (var i = 0; i < eventNames.length; i++) {
    var e = eventNames[i];
    if (elem.addEventListener) {
      elem.addEventListener(e, genOp, false);
    } else {
      elem.attachEvent('on' + e, genOp);
    }
  }

  ctx.detach = function() {
    for (var i = 0; i < eventNames.length; i++) {
      var e = eventNames[i];
      if (elem.removeEventListener) {
        elem.removeEventListener(e, genOp, false);
      } else {
        elem.detachEvent('on' + e, genOp);
      }
    }
  };

  return ctx;
};

var Doc;
if (typeof brequire !== 'undefined') {
  Doc = brequire('./doc').Doc;
}

// Queries are live requests to the database for particular sets of fields.
//
// The server actively tells the client when there's new data that matches
// a set of conditions.
var Query = exports.Query = function(type, connection, id, collection, query, options, callback) {
  // 'fetch' or 'sub'
  this.type = type;

  this.connection = connection;
  this.id = id;
  this.collection = collection;

  // The query itself. For mongo, this should look something like {"data.x":5}
  this.query = query;

  // Resultant document action for the server. Fetch mode will automatically
  // fetch all results. Subscribe mode will automatically subscribe all
  // results. Results are never unsubscribed.
  this.docMode = options.docMode; // undefined, 'fetch' or 'sub'.
  if (this.docMode === 'subscribe') this.docMode = 'sub';

  // Do we repoll the entire query whenever anything changes? (As opposed to
  // just polling the changed item). This needs to be enabled to be able to use
  // ordered queries (sortby:) and paginated queries. Set to undefined, it will
  // be enabled / disabled automatically based on the query's properties.
  this.poll = options.poll;

  // The backend we actually hit. If this isn't defined, it hits the snapshot
  // database. Otherwise this can be used to hit another configured query
  // index.
  this.backend = options.backend || options.source;

  // A list of resulting documents. These are actual documents, complete with
  // data and all the rest. If fetch is false, these documents will not
  // have any data. You should manually call fetch() or subscribe() on them.
  //
  // Calling subscribe() might be a good idea anyway, as you won't be
  // subscribed to the documents by default.
  this.knownDocs = options.knownDocs || [];
  this.results = [];

  // Do we have some initial data?
  this.ready = false;

  this.callback = callback;
};
Query.prototype.action = 'qsub';

// Helper for subscribe & fetch, since they share the same message format.
//
// This function actually issues the query.
Query.prototype._execute = function() {
  if (!this.connection.canSend) return;

  if (this.docMode) {
    var collectionVersions = {};
    // Collect the version of all the documents in the current result set so we
    // don't need to be sent their snapshots again.
    for (var i = 0; i < this.knownDocs.length; i++) {
      var doc = this.knownDocs[i];
      var c = collectionVersions[doc.collection] = collectionVersions[doc.collection] || {};
      c[doc.name] = doc.version;
    }
  }

  var msg = {
    a: 'q' + this.type,
    id: this.id,
    c: this.collection,
    o: {},
    q: this.query,
  };

  if (this.docMode) {
    msg.o.m = this.docMode;
    // This should be omitted if empty, but whatever.
    msg.o.vs = collectionVersions;
  }
  if (this.backend != null) msg.o.b = this.backend;
  if (this.poll !== undefined) msg.o.p = this.poll;

  this.connection.send(msg);
};

// Make a list of documents from the list of server-returned data objects
Query.prototype._dataToDocs = function(data) {
  var results = [];
  var lastType;
  for (var i = 0; i < data.length; i++) {
    var docData = data[i];

    // Types are only put in for the first result in the set and every time the type changes in the list.
    if (docData.type) {
      lastType = docData.type;
    } else {
      docData.type = lastType;
    }

    var doc = this.connection.get(docData.c || this.collection, docData.d, docData);
    // Force the document to know its subscribed if we're in docmode:subscribe.
    if (this.docMode === 'sub') {
      doc.subscribed = true; // Set before setWantSubscribe() so flush doesn't send a subscribe request.
      doc._setWantSubscribe(true); // this will call any subscribe callbacks or whatever.
      doc.emit('subscribe');
      doc._finishSub(true); // this doesn't actually do anything here, but its more correct to have it.
    }
    results.push(doc);
  }
  return results;
};

// Destroy the query object. Any subsequent messages for the query will be
// ignored by the connection. You should unsubscribe from the query before
// destroying it.
Query.prototype.destroy = function() {
  if (this.connection.canSend && this.type === 'sub') {
    this.connection.send({a:'qunsub', id:this.id});
  }

  this.connection._destroyQuery(this);
};

Query.prototype._onConnectionStateChanged = function(state, reason) {
  if (this.connection.state === 'connecting') {
    this._execute();
  }
};

// Internal method called from connection to pass server messages to the query.
Query.prototype._onMessage = function(msg) {
  if ((msg.a === 'qfetch') !== (this.type === 'fetch')) {
    if (console) console.warn('Invalid message sent to query', msg, this);
    return;
  }

  if (msg.error) this.emit('error', msg.error);

  switch (msg.a) {
    case 'qfetch':
      var results = msg.data ? this._dataToDocs(msg.data) : undefined;
      if (this.callback) this.callback(msg.error, results, msg.extra);
      // Once a fetch query gets its data, it is destroyed.
      this.connection._destroyQuery(this);
      break;

    case 'q':
      // Query diff data (inserts and removes)
      if (msg.diff) {
        // We need to go through the list twice. First, we'll injest all the
        // new documents and set them as subscribed.  After that we'll emit
        // events and actually update our list. This avoids race conditions
        // around setting documents to be subscribed & unsubscribing documents
        // in event callbacks.
        for (var i = 0; i < msg.diff.length; i++) {
          var d = msg.diff[i];
          if (d.type === 'insert') d.values = this._dataToDocs(d.values);
        }

        for (var i = 0; i < msg.diff.length; i++) {
          var d = msg.diff[i];
          switch (d.type) {
            case 'insert':
              var newDocs = d.values;
              Array.prototype.splice.apply(this.results, [d.index, 0].concat(newDocs));
              this.emit('insert', newDocs, d.index);
              break;
            case 'remove':
              var howMany = d.howMany || 1;
              var removed = this.results.splice(d.index, howMany);
              this.emit('remove', removed, d.index);
              break;
            case 'move':
              var howMany = d.howMany || 1;
              var docs = this.results.splice(d.from, howMany);
              Array.prototype.splice.apply(this.results, [d.to, 0].concat(docs));
              this.emit('move', docs, d.from, d.to);
              break;
          }
        }
      }

      if (msg.extra) {
        this.emit('extra', msg.extra);
      }
      break;
    case 'qsub':
      // This message replaces the entire result set with the set passed.
      if (!msg.error) {
        var previous = this.results;

        // Then add everything in the new result set.
        this.results = this.knownDocs = this._dataToDocs(msg.data);
        this.extra = msg.extra;

        this.ready = true;
        this.emit('change', this.results, previous);
      }
      if (this.callback) {
        this.callback(msg.error, this.results, this.extra);
        delete this.callback;
      }
      break;
  }
};

// Change the thing we're searching for. This isn't fully supported on the
// backend (it destroys the old query and makes a new one) - but its
// programatically useful and I might add backend support at some point.
Query.prototype.setQuery = function(q) {
  if (this.type !== 'sub') throw new Error('cannot change a fetch query');

  this.query = q;
  if (this.connection.canSend) {
    // There's no 'change' message to send to the server. Just resubscribe.
    this.connection.send({a:'qunsub', id:this.id});
    this._execute();
  }
};

var MicroEvent;
if (typeof brequire !== 'undefined') {
  MicroEvent = brequire('./microevent');
}

MicroEvent.mixin(Query);

})();
