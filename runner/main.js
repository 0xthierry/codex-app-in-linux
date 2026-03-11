const path = require("node:path");
const { app, dialog } = require("electron");

Object.defineProperty(app, "isPackaged", {
  configurable: true,
  get() {
    return true;
  },
});

app.setName("Codex");
app.setVersion("26.309.31024");

const wrapperResourcesPath = path.join(__dirname, "resources");
process.env.CODEX_CLI_PATH ||= path.join(wrapperResourcesPath, "bin", "codex");
const appRoot = process.env.CODEX_APP_ROOT || path.join(
  __dirname,
  "..",
  ".codex-linux-runtime",
  "app",
);

const originalShowMessageBox = dialog.showMessageBox.bind(dialog);
dialog.showMessageBox = async (options, ...rest) => {
  console.error("codex-dialog-detail:", options?.detail ?? "<no detail>");
  return originalShowMessageBox(options, ...rest);
};

require(path.join(
  appRoot,
  ".vite",
  "build",
  "bootstrap.js",
));
