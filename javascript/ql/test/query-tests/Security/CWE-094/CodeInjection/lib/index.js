export function unsafeDeserialize(data) {
  return eval("(" + data + ")"); // NOT OK
}

export function unsafeGetter(obj, name) {
    return eval("obj." + name); // NOT OK
}

export function safeAssignment(obj, value) {
    eval("obj.foo = " + JSON.stringify(value)); // OK
}

global.unsafeDeserialize = function (data) {
  return eval("(" + data + ")"); // NOT OK
}

const matter = require("gray-matter");

export function greySink(data) {
    const str = `
    ---js
    ${data}
    ---
    `
    const res = matter(str);
    console.log(res);

    matter(str, { // OK
        engines: {
            js: function (data) {
                console.log("NOPE");
            }
        }
    });
}

function codeIsAlive() {
  new Template().compile();
}

export function Template(text, opts) {
  opts = opts || {};
  var options = {};
  options.varName = opts.varName;
  this.opts = options;
}

Template.prototype = {
  compile: function () {
    var opts = this.opts;
    eval("  var " + opts.varName + " = something();"); // NOT OK
  },
  pathsTerminate1: function (node, prev) {
    node.tree = {
      ancestor: node,
      number: rand ? prev.tree.number + 1 : 0,
    };
  },
  pathsTerminate2: function (A) {
    try {
      var B = A.p1;
      var C = B.p2;
      C.p5 = C;
    } catch (ex) {}
  },
};


