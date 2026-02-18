import { BrowserWindow, Utils, ApplicationMenu, Screen } from "electrobun/bun";

const primary = Screen.getPrimaryDisplay();
const winW = 1200;
const winH = 760;
const x = Math.round((primary.workArea.width - winW) / 2) + primary.workArea.x;
const y = Math.round((primary.workArea.height - winH) / 2) + primary.workArea.y;

const mainWindow = new BrowserWindow({
  title: "Den",
  url: "views://mainview/index.html",
  frame: { width: winW, height: winH, x, y },
  titleBarStyle: "hiddenInset",
});

mainWindow.on("close", () => {
  Utils.quit();
});

ApplicationMenu.setApplicationMenu([
  {
    submenu: [
      { label: "About Den", role: "about" },
      { type: "separator" },
      { label: "Hide Den", role: "hide" },
      { label: "Hide Others", role: "hideOthers" },
      { label: "Show All", role: "showAll" },
      { type: "separator" },
      { label: "Quit Den", role: "quit" },
    ],
  },
  {
    label: "Edit",
    submenu: [
      { role: "undo" },
      { role: "redo" },
      { type: "separator" },
      { role: "cut" },
      { role: "copy" },
      { role: "paste" },
      { role: "selectAll" },
    ],
  },
  {
    label: "View",
    submenu: [{ label: "Enter Full Screen", role: "enterFullScreen" }],
  },
  {
    label: "Window",
    submenu: [
      { label: "Minimize", role: "minimize" },
      { label: "Zoom", role: "zoom" },
      { type: "separator" },
      { label: "Bring All to Front", role: "bringAllToFront" },
    ],
  },
]);
