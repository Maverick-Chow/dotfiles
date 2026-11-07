// Pane navigation like vim-tmux-navigator, plus moving out of a zoomed pane.
// Draws nothing: it sits in a layout as a floating block only to receive
// commands from keys.json and from Neovim (`herdr-app do pane-nav.go-left`).
//   pane-nav.left|down|up|right        ctrl+h/j/k/l: Neovim gets the key, else go
//   pane-nav.go-left|go-down|...       always go (Neovim at its edge, ctrl+a h/j/k/l)
// Going from a zoomed pane unzooms first, as tmux does.

import { View, div } from "gpui-kit";
import { panes, focused, run, hc, nextCommand } from "herdr";

const KEY = { left: "ctrl+h", down: "ctrl+j", up: "ctrl+k", right: "ctrl+l" };
const VIM = new Set(["nvim", "vim", "vi", "view"]);

export default class PaneNav extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      for (;;) {
        const c = await nextCommand();
        const go = c.startsWith("go-");
        const dir = go ? c.slice(3) : c;
        if (!KEY[dir]) continue;
        const f = focused();
        const pane = f?.pane && panes().find((p) => p.pane === f.pane);
        if (!go && pane?.terminal && VIM.has(pane.program?.key)) {
          await hc(["keys", pane.terminal, KEY[dir]]);
          continue;
        }
        if (pane?.zoomed) run("pane.zoom", { pane: pane.pane });
        run("pane.go", { direction: dir });
      }
    });
  }

  render() {
    return div();
  }
}
