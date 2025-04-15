
const fs = require("fs");
const path = "lib/main.js";
const shebang = "#!/usr/bin/env node\n";

let content = fs.readFileSync(path, "utf8");
if (!content.startsWith("#!")) {
  fs.writeFileSync(path, shebang + content);
}
