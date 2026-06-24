"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/select-wallpaper.tsx
var select_wallpaper_exports = {};
__export(select_wallpaper_exports, {
  default: () => Command
});
module.exports = __toCommonJS(select_wallpaper_exports);
var import_api = require("@raycast/api");
var import_react = require("react");
var childProcess = __toESM(require("child_process"));
var import_fs = __toESM(require("fs"));
var import_path = __toESM(require("path"));
var import_jsx_runtime = require("react/jsx-runtime");
var WALLS_DIR = `${process.env.HOME}/Pictures/walls`;
var WALLPAPER_DIRS = [];
if (import_fs.default.existsSync(WALLS_DIR)) {
  const wallSubDirs = import_fs.default.readdirSync(WALLS_DIR, { withFileTypes: true }).filter((dirent) => dirent.isDirectory()).map((dirent) => import_path.default.join(WALLS_DIR, dirent.name));
  WALLPAPER_DIRS.push(...wallSubDirs);
}
var CACHE_FILE = `${process.env.HOME}/.cache/current_wallpaper.txt`;
async function runShellCommand(command) {
  try {
    const result = await new Promise((resolve, reject) => {
      childProcess.exec(command, (error, stdout, stderr) => {
        if (error) {
          reject(error);
        } else {
          resolve(stdout.toString());
        }
      });
    });
    console.log(result);
  } catch (error) {
    console.error(error);
  }
}
function Command() {
  const favoritesPath = import_path.default.join(WALLS_DIR, "favorites");
  const [selectedFolder, setSelectedFolder] = (0, import_react.useState)(
    import_fs.default.existsSync(favoritesPath) ? favoritesPath : WALLPAPER_DIRS[0]
  );
  const [wallpapers, setWallpapers] = (0, import_react.useState)([]);
  const [isLoading, setIsLoading] = (0, import_react.useState)(true);
  const loadWallpapers = (folder) => {
    try {
      const dir = folder;
      const files = import_fs.default.readdirSync(dir).filter((file) => file.match(/\.(jpe?g|png|heic)$/i)).map((file) => ({
        path: import_path.default.join(dir, file)
      }));
      setWallpapers(files);
    } catch (error) {
      (0, import_api.showToast)({
        style: import_api.Toast.Style.Failure,
        title: "Failed to load wallpapers",
        message: String(error)
      });
    } finally {
      setIsLoading(false);
    }
  };
  (0, import_react.useEffect)(() => {
    setIsLoading(true);
    loadWallpapers(selectedFolder);
  }, [selectedFolder]);
  return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
    import_api.List,
    {
      isLoading,
      isShowingDetail: true,
      searchBarPlaceholder: "Pick a wallpaper...",
      searchBarAccessory: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api.List.Dropdown, { tooltip: "Select Folder", value: selectedFolder, onChange: setSelectedFolder, children: WALLPAPER_DIRS.map((dir) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api.List.Dropdown.Item, { title: import_path.default.basename(dir), value: dir }, dir)) }),
      children: wallpapers.map((wp) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
        import_api.List.Item,
        {
          title: import_path.default.basename(wp.path, import_path.default.extname(wp.path)).replace(/[-_]/g, " "),
          detail: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api.List.Item.Detail, { markdown: `![preview](${wp.path})` }),
          actions: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_api.ActionPanel, { children: [
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)(
              import_api.Action,
              {
                title: "Use This Wallpaper",
                onAction: async () => {
                  import_fs.default.writeFileSync(CACHE_FILE, wp.path);
                  await (0, import_api.showToast)({ title: "Wallpaper path saved", message: wp.path });
                  await (0, import_api.closeMainWindow)({ clearRootSearch: true });
                  await runShellCommand("$HOME/.local/bin/pywall");
                }
              }
            ),
            /* @__PURE__ */ (0, import_jsx_runtime.jsx)(import_api.Action.CopyToClipboard, { title: "Copy Path", content: wp.path })
          ] })
        },
        wp.path
      ))
    }
  );
}
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiLi4vLi4vLi4vLi4vRGV2ZWxvcGVyL3JheWNhc3QvcGx1Z2lucy93cHNlbGVjdG9yL3NyYy9zZWxlY3Qtd2FsbHBhcGVyLnRzeCJdLAogICJzb3VyY2VzQ29udGVudCI6IFsiaW1wb3J0IHsgQWN0aW9uLCBBY3Rpb25QYW5lbCwgY2xvc2VNYWluV2luZG93LCBMaXN0LCBzaG93VG9hc3QsIFRvYXN0IH0gZnJvbSBcIkByYXljYXN0L2FwaVwiO1xuaW1wb3J0IHsgdXNlRWZmZWN0LCB1c2VTdGF0ZSB9IGZyb20gXCJyZWFjdFwiO1xuXG5pbXBvcnQgKiBhcyBjaGlsZFByb2Nlc3MgZnJvbSAnY2hpbGRfcHJvY2Vzcyc7XG5cbmltcG9ydCBmcyBmcm9tIFwiZnNcIjtcbmltcG9ydCBwYXRoIGZyb20gXCJwYXRoXCI7XG5cbmNvbnN0IFdBTExTX0RJUiA9IGAke3Byb2Nlc3MuZW52LkhPTUV9L1BpY3R1cmVzL3dhbGxzYDtcblxuLy8gU3RhcnQgd2l0aCBiYXNlIGZvbGRlcnNcbmNvbnN0IFdBTExQQVBFUl9ESVJTOiBzdHJpbmdbXSA9IFtdO1xuXG4vLyBBZGQgYWxsIHN1YmRpcmVjdG9yaWVzIGluIFdBTExTX0RJUlxuaWYgKGZzLmV4aXN0c1N5bmMoV0FMTFNfRElSKSkge1xuICBjb25zdCB3YWxsU3ViRGlycyA9IGZzXG4gICAgLnJlYWRkaXJTeW5jKFdBTExTX0RJUiwgeyB3aXRoRmlsZVR5cGVzOiB0cnVlIH0pXG4gICAgLmZpbHRlcigoZGlyZW50KSA9PiBkaXJlbnQuaXNEaXJlY3RvcnkoKSlcbiAgICAubWFwKChkaXJlbnQpID0+IHBhdGguam9pbihXQUxMU19ESVIsIGRpcmVudC5uYW1lKSk7XG5cbiAgV0FMTFBBUEVSX0RJUlMucHVzaCguLi53YWxsU3ViRGlycyk7XG59XG5cbmNvbnN0IENBQ0hFX0ZJTEUgPSBgJHtwcm9jZXNzLmVudi5IT01FfS8uY2FjaGUvY3VycmVudF93YWxscGFwZXIudHh0YDtcblxuaW50ZXJmYWNlIFdhbGxwYXBlciB7XG4gIHBhdGg6IHN0cmluZztcbn1cblxuYXN5bmMgZnVuY3Rpb24gcnVuU2hlbGxDb21tYW5kKGNvbW1hbmQ6IHN0cmluZykge1xuICB0cnkge1xuICAgIGNvbnN0IHJlc3VsdCA9IGF3YWl0IG5ldyBQcm9taXNlKChyZXNvbHZlLCByZWplY3QpID0+IHtcbiAgICAgIGNoaWxkUHJvY2Vzcy5leGVjKGNvbW1hbmQsIChlcnJvciwgc3Rkb3V0LCBzdGRlcnIpID0+IHtcbiAgICAgICAgaWYgKGVycm9yKSB7XG4gICAgICAgICAgcmVqZWN0KGVycm9yKTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICByZXNvbHZlKHN0ZG91dC50b1N0cmluZygpKTtcbiAgICAgICAgfVxuICAgICAgfSk7XG4gICAgfSk7XG4gICAgY29uc29sZS5sb2cocmVzdWx0KTtcbiAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICBjb25zb2xlLmVycm9yKGVycm9yKTtcbiAgfVxufVxuXG5leHBvcnQgZGVmYXVsdCBmdW5jdGlvbiBDb21tYW5kKCkge1xuICBjb25zdCBmYXZvcml0ZXNQYXRoID0gcGF0aC5qb2luKFdBTExTX0RJUiwgXCJmYXZvcml0ZXNcIik7XG4gIGNvbnN0IFtzZWxlY3RlZEZvbGRlciwgc2V0U2VsZWN0ZWRGb2xkZXJdID0gdXNlU3RhdGUoXG4gICAgZnMuZXhpc3RzU3luYyhmYXZvcml0ZXNQYXRoKSA/IGZhdm9yaXRlc1BhdGggOiBXQUxMUEFQRVJfRElSU1swXSxcbiAgKTtcbiAgY29uc3QgW3dhbGxwYXBlcnMsIHNldFdhbGxwYXBlcnNdID0gdXNlU3RhdGU8V2FsbHBhcGVyW10+KFtdKTtcbiAgY29uc3QgW2lzTG9hZGluZywgc2V0SXNMb2FkaW5nXSA9IHVzZVN0YXRlKHRydWUpO1xuXG4gIGNvbnN0IGxvYWRXYWxscGFwZXJzID0gKGZvbGRlcjogc3RyaW5nKSA9PiB7XG4gICAgdHJ5IHtcbiAgICAgIGNvbnN0IGRpciA9IGZvbGRlcjtcbiAgICAgIGNvbnN0IGZpbGVzID0gZnNcbiAgICAgICAgLnJlYWRkaXJTeW5jKGRpcilcbiAgICAgICAgLmZpbHRlcigoZmlsZSkgPT4gZmlsZS5tYXRjaCgvXFwuKGpwZT9nfHBuZ3xoZWljKSQvaSkpXG4gICAgICAgIC5tYXAoKGZpbGUpID0+ICh7XG4gICAgICAgICAgcGF0aDogcGF0aC5qb2luKGRpciwgZmlsZSksXG4gICAgICAgIH0pKTtcblxuICAgICAgc2V0V2FsbHBhcGVycyhmaWxlcyk7XG4gICAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICAgIHNob3dUb2FzdCh7XG4gICAgICAgIHN0eWxlOiBUb2FzdC5TdHlsZS5GYWlsdXJlLFxuICAgICAgICB0aXRsZTogXCJGYWlsZWQgdG8gbG9hZCB3YWxscGFwZXJzXCIsXG4gICAgICAgIG1lc3NhZ2U6IFN0cmluZyhlcnJvciksXG4gICAgICB9KTtcbiAgICB9IGZpbmFsbHkge1xuICAgICAgc2V0SXNMb2FkaW5nKGZhbHNlKTtcbiAgICB9XG4gIH07XG5cbiAgdXNlRWZmZWN0KCgpID0+IHtcbiAgICBzZXRJc0xvYWRpbmcodHJ1ZSk7XG4gICAgbG9hZFdhbGxwYXBlcnMoc2VsZWN0ZWRGb2xkZXIpO1xuICB9LCBbc2VsZWN0ZWRGb2xkZXJdKTtcblxuICByZXR1cm4gKFxuICAgIDxMaXN0XG4gICAgICBpc0xvYWRpbmc9e2lzTG9hZGluZ31cbiAgICAgIGlzU2hvd2luZ0RldGFpbFxuICAgICAgc2VhcmNoQmFyUGxhY2Vob2xkZXI9XCJQaWNrIGEgd2FsbHBhcGVyLi4uXCJcbiAgICAgIHNlYXJjaEJhckFjY2Vzc29yeT17XG4gICAgICAgIDxMaXN0LkRyb3Bkb3duIHRvb2x0aXA9XCJTZWxlY3QgRm9sZGVyXCIgdmFsdWU9e3NlbGVjdGVkRm9sZGVyfSBvbkNoYW5nZT17c2V0U2VsZWN0ZWRGb2xkZXJ9PlxuICAgICAgICAgIHtXQUxMUEFQRVJfRElSUy5tYXAoKGRpcikgPT4gKFxuICAgICAgICAgICAgPExpc3QuRHJvcGRvd24uSXRlbSBrZXk9e2Rpcn0gdGl0bGU9e3BhdGguYmFzZW5hbWUoZGlyKX0gdmFsdWU9e2Rpcn0gLz5cbiAgICAgICAgICApKX1cbiAgICAgICAgPC9MaXN0LkRyb3Bkb3duPlxuICAgICAgfVxuICAgID5cbiAgICAgIHt3YWxscGFwZXJzLm1hcCgod3ApID0+IChcbiAgICAgICAgPExpc3QuSXRlbVxuICAgICAgICAgIGtleT17d3AucGF0aH1cbiAgICAgICAgICB0aXRsZT17cGF0aC5iYXNlbmFtZSh3cC5wYXRoLCBwYXRoLmV4dG5hbWUod3AucGF0aCkpLnJlcGxhY2UoL1stX10vZywgXCIgXCIpfVxuICAgICAgICAgIGRldGFpbD17PExpc3QuSXRlbS5EZXRhaWwgbWFya2Rvd249e2AhW3ByZXZpZXddKCR7d3AucGF0aH0pYH0gLz59XG4gICAgICAgICAgYWN0aW9ucz17XG4gICAgICAgICAgICA8QWN0aW9uUGFuZWw+XG4gICAgICAgICAgICAgIDxBY3Rpb25cbiAgICAgICAgICAgICAgICB0aXRsZT1cIlVzZSBUaGlzIFdhbGxwYXBlclwiXG4gICAgICAgICAgICAgICAgb25BY3Rpb249e2FzeW5jICgpID0+IHtcbiAgICAgICAgICAgICAgICAgIGZzLndyaXRlRmlsZVN5bmMoQ0FDSEVfRklMRSwgd3AucGF0aCk7XG4gICAgICAgICAgICAgICAgICBhd2FpdCBzaG93VG9hc3QoeyB0aXRsZTogXCJXYWxscGFwZXIgcGF0aCBzYXZlZFwiLCBtZXNzYWdlOiB3cC5wYXRoIH0pO1xuICAgICAgICAgICAgICAgICAgYXdhaXQgY2xvc2VNYWluV2luZG93KHsgY2xlYXJSb290U2VhcmNoOiB0cnVlIH0pO1xuICAgICAgICAgICAgICAgICAgYXdhaXQgcnVuU2hlbGxDb21tYW5kKCckSE9NRS8ubG9jYWwvYmluL3B5d2FsbCcpO1xuICAgICAgICAgICAgICAgIH19XG4gICAgICAgICAgICAgIC8+XG4gICAgICAgICAgICAgIDxBY3Rpb24uQ29weVRvQ2xpcGJvYXJkIHRpdGxlPVwiQ29weSBQYXRoXCIgY29udGVudD17d3AucGF0aH0gLz5cbiAgICAgICAgICAgIDwvQWN0aW9uUGFuZWw+XG4gICAgICAgICAgfVxuICAgICAgICAvPlxuICAgICAgKSl9XG4gICAgPC9MaXN0PlxuICApO1xufVxuIl0sCiAgIm1hcHBpbmdzIjogIjs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0FBQUE7QUFBQTtBQUFBO0FBQUE7QUFBQTtBQUFBLGlCQUE2RTtBQUM3RSxtQkFBb0M7QUFFcEMsbUJBQThCO0FBRTlCLGdCQUFlO0FBQ2Ysa0JBQWlCO0FBbUZMO0FBakZaLElBQU0sWUFBWSxHQUFHLFFBQVEsSUFBSSxJQUFJO0FBR3JDLElBQU0saUJBQTJCLENBQUM7QUFHbEMsSUFBSSxVQUFBQSxRQUFHLFdBQVcsU0FBUyxHQUFHO0FBQzVCLFFBQU0sY0FBYyxVQUFBQSxRQUNqQixZQUFZLFdBQVcsRUFBRSxlQUFlLEtBQUssQ0FBQyxFQUM5QyxPQUFPLENBQUMsV0FBVyxPQUFPLFlBQVksQ0FBQyxFQUN2QyxJQUFJLENBQUMsV0FBVyxZQUFBQyxRQUFLLEtBQUssV0FBVyxPQUFPLElBQUksQ0FBQztBQUVwRCxpQkFBZSxLQUFLLEdBQUcsV0FBVztBQUNwQztBQUVBLElBQU0sYUFBYSxHQUFHLFFBQVEsSUFBSSxJQUFJO0FBTXRDLGVBQWUsZ0JBQWdCLFNBQWlCO0FBQzlDLE1BQUk7QUFDRixVQUFNLFNBQVMsTUFBTSxJQUFJLFFBQVEsQ0FBQyxTQUFTLFdBQVc7QUFDcEQsTUFBYSxrQkFBSyxTQUFTLENBQUMsT0FBTyxRQUFRLFdBQVc7QUFDcEQsWUFBSSxPQUFPO0FBQ1QsaUJBQU8sS0FBSztBQUFBLFFBQ2QsT0FBTztBQUNMLGtCQUFRLE9BQU8sU0FBUyxDQUFDO0FBQUEsUUFDM0I7QUFBQSxNQUNGLENBQUM7QUFBQSxJQUNILENBQUM7QUFDRCxZQUFRLElBQUksTUFBTTtBQUFBLEVBQ3BCLFNBQVMsT0FBTztBQUNkLFlBQVEsTUFBTSxLQUFLO0FBQUEsRUFDckI7QUFDRjtBQUVlLFNBQVIsVUFBMkI7QUFDaEMsUUFBTSxnQkFBZ0IsWUFBQUEsUUFBSyxLQUFLLFdB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
