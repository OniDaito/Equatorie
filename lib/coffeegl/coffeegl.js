// Generated by CoffeeScript 1.6.1

/* ABOUT
                       __  .__              ________ 
   ______ ____   _____/  |_|__| ____   ____/   __   \
  /  ___// __ \_/ ___\   __\  |/  _ \ /    \____    /
  \___ \\  ___/\  \___|  | |  (  <_> )   |  \ /    / 
 /____  >\___  >\___  >__| |__|\____/|___|  //____/  .co.uk
      \/     \/     \/                    \/         
                                              CoffeeGL
                                              Benjamin Blundell - ben@section9.co.uk
                                              http://www.section9.co.uk

This software is released under the MIT Licence. See LICENCE.txt for details


- Resources

* http://www.yuiblog.com/blog/2007/06/12/module-pattern/
* http://www.plexical.com/blog/2012/01/25/writing-coffeescript-for-browser-and-nod/
* https://github.com/field/FieldKit.js

- TODO
* Need a shorthand here for sure!
*/


/* CoffeeGL entry point
*/


(function() {
  var CoffeeGL, GL, extend, util, _setupFrame;

  CoffeeGL = {};

  GL = {};

  util = require('./util');

  extend = function() {
    var pkg;
    switch (arguments.length) {
      case 1:
        return util.extend(CoffeeGL, arguments[0]);
      case 2:
        pkg = arguments[0];
        if (CoffeeGL[pkg] == null) {
          CoffeeGL[pkg] = {};
        }
        return util.extend(CoffeeGL[pkg], arguments[1]);
    }
  };

  if (typeof window !== "undefined" && window !== null) {
    window.CoffeeGL = CoffeeGL;
  }

  if (typeof window !== "undefined" && window !== null) {
    window.GL = GL;
  }

  extend(require('./app'));

  extend(require('./math'));

  extend("Colour", require('./colour'));

  extend(require('./primitives'));

  extend(require('./node'));

  extend(require('./model'));

  extend(require('./shader'));

  extend(require('./request'));

  extend(require('./fbo'));

  extend(require('./texture'));

  extend("Camera", require('./camera'));

  extend("Shapes", require('./shapes'));

  extend(require('./webgl'));

  extend(require('./util'));

  extend(require('./signal'));

  extend("Light", require('./light'));

  extend(require('./material'));

  extend(require('./error'));

  extend(require('./functions'));

  extend(require('./animation'));

  _setupFrame = function(root) {
    var onEachFrame;
    if (root.webkitRequestAnimationFrame) {
      onEachFrame = function(cb) {
        var _cb;
        _cb = function() {
          cb();
          return webkitRequestAnimationFrame(_cb);
        };
        return _cb();
      };
    } else if (root.mozRequestAnimationFrame) {
      onEachFrame = function(cb) {
        var _cb;
        _cb = function() {
          cb();
          return mozRequestAnimationFrame(_cb);
        };
        return _cb();
      };
    } else {
      onEachFrame = function(cb) {
        return setInterval(cb, 1000 / 60);
      };
    }
    return root.onEachFrame = onEachFrame;
  };

  if (typeof window !== "undefined" && window !== null) {
    _setupFrame(window);
  }

  module.exports = {
    CoffeeGL: CoffeeGL,
    GL: GL
  };

}).call(this);
