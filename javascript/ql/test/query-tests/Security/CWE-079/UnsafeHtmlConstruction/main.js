module.exports.xssThroughHTMLConstruction = function (s) {
    const html = "<span>" + s + "</span>";// NOT OK
    document.querySelector("#html").innerHTML = html;
}
 
module.exports.xssThroughXMLParsing = function (s) {
    const doc = new DOMParser().parseFromString(s, "text/xml"); // NOT OK
    document.querySelector("#xml").appendChild(doc.documentElement);
}

module.exports.xssThroughMoreComplexXMLParsing = function (s) {
    const doc = new DOMParser().parseFromString(s, "text/xml"); // NOT OK
    const xml = doc.documentElement;
    
    const tmp = document.createElement('span');
    tmp.appendChild(xml.cloneNode()); 
    document.querySelector("#xml").appendChild(tmp);
}

const markdown = require('markdown-it')({html: true});
module.exports.xssThroughMarkdown = function (s) {
    const html = markdown.render(s); // NOT OK
    document.querySelector("#markdown").innerHTML = html;
}

const striptags = require('striptags');
module.exports.sanitizedHTML = function (s) {
    const html = striptags("<span>" + s + "</span>"); // OK
    document.querySelector("#sanitized").innerHTML = html;
}

module.exports.ts = require("./typed");

module.exports.jquery = require("./jquery-plugin");

module.exports.plainDOMXMLParsing = function (s) {
    const doc = new DOMParser().parseFromString(s, "text/xml"); // OK - is never added to the DOM.
}

class Foo {
    constructor(s) {
        this.step = s;
    }

    doXss() {
        // not called here, but still bad.
        document.querySelector("#class").innerHTML = "<span>" + this.step + "</span>"; // NOT OK
    }

}

module.exports.createsClass = function (s) {
    return new Foo(s);
}
