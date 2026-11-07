// ctrl+a actions that need more than one command. Draws nothing: it sits in a
// layout as a floating block only to receive commands from keys.json.
//   prefix-keys.tab-left|tab-right     move the shown tab one place (tmux swap-window)
//   prefix-keys.files|changes          show that side panel, or hide it if it's showing

import { View, div } from "gpui-kit";
import { spaces, layout, run, nextCommand } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

export default class PrefixKeys extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      for (;;) {
        const c = await nextCommand();
        if (c === "tab-left" || c === "tab-right") {
          const tabs = spaces().find((s) => s.active)?.tabs ?? [];
          const i = tabs.findIndex((t) => t.active);
          const to = i + (c === "tab-left" ? -1 : 1);
          if (i >= 0 && to >= 0 && to < tabs.length) run("tab.move", { id: tabs[i].id, index: to + 1 });
        } else if (c === "files" || c === "changes") {
          const root = layout(), panel = find(root, "panel"), body = find(root, "panel-body");
          if (panel && !panel.hidden && body?.active === c) run("layout.hide", { id: "panel" });
          else { run("layout.select", { stack: "panel-body", child: c }); run("layout.show", { id: "panel" }); }
        }
      }
    });
  }

  render() {
    return div();
  }
}
