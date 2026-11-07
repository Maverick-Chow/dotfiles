// ctrl+a actions that need more than one command. Draws nothing: it sits in a
// layout as a floating block only to receive commands from keys.json.
//   prefix-keys.tab-left|tab-right     move the shown tab one place (tmux swap-window)
//   prefix-keys.files|changes          show that side panel, or hide it if it's showing
//   prefix-keys.copy                   tmux copy mode: the focused terminal's screen and history,
//                                      read-only in Neovim in a zoomed split (y yanks to the
//                                      clipboard, q closes it and the split with it)

import { View, div } from "gpui-kit";
import { spaces, layout, panes, focused, run, nextCommand } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

// The pane leaves when Neovim quits, since its terminal ends with it.
const copyMode = (terminal) => [
  "sh", "-c",
  `H=$(command -v hc || echo "$HOME/.local/bin/hc"); N=$(command -v nvim || echo /opt/homebrew/bin/nvim); ` +
  `"$H" read ${terminal} --lines 100000 | "$N" -R -c 'set nomodified' -c 'nnoremap <buffer> q <cmd>q!<cr>' -c 'normal! G' -`,
];

export default class PrefixKeys extends View {
  init(_props, cx) {
    const wait = (ms) => new Promise((resolve) => cx.timer.after(ms, resolve));
    cx.spawn(async () => {
      for (;;) {
        const c = await nextCommand();
        if (c === "tab-left" || c === "tab-right") {
          const tabs = spaces().find((s) => s.active)?.tabs ?? [];
          const i = tabs.findIndex((t) => t.active);
          const to = i + (c === "tab-left" ? -1 : 1);
          if (i >= 0 && to >= 0 && to < tabs.length) run("tab.move", { id: tabs[i].id, index: to + 1 });
        } else if (c === "copy") {
          const terminal = focused()?.terminal;
          if (!terminal) continue;
          const before = new Set(panes().map((p) => p.pane));
          run("pane.split", { direction: "down", argv: copyMode(terminal) });
          for (let i = 0; i < 40; i++) {
            const added = panes().find((p) => !before.has(p.pane));
            if (added) { run("pane.zoom", { pane: added.pane }); break; }
            await wait(25);
          }
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
