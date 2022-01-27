const fs = require("fs");
const os = require("os");
const path = require("path");

const filePath = path.join(os.tmpdir(), "my-temp-file.txt");

if (!fs.existsSync(filePath)) {
  fs.writeFileSync(filePath, "Hello", { mode: 0o600 }); // NOT OK
}

const filePath2 = createFile();
const stats = fs.statSync(filePath2);
if (doSomethingWith(stats)) {
    fs.writeFileSync(filePath2, "content"); // NOT OK
}

fs.access(filePath2, fs.constants.F_OK, (err) => {
    fs.writeFileSync(filePath2, "content"); // NOT OK
});

fs.open("myFile", "rw", (err, fd) => {
    fs.writeFileSync(fd, "content"); // OK
});