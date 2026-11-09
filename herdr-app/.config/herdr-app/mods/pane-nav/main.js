// Pane navigation that leaves a zoomed pane, as tmux does. Draws nothing: it
// sits in a layout as a floating block only to receive commands from keys.json
// (ctrl+h/j/k/l and ctrl+a h/j/k/l). Neovim moves between its own splits with
// <leader>d h/j/k/l instead, so herdr never has to hand it the key.
//   pane-nav.go-left|go-down|go-up|go-right

import { View, div } from "gpui-kit";
import { panes, focused, run, nextCommand } from "herdr";

const DIRS = new Set(["left", "down", "up", "right"]);

export default class PaneNav extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      for (;;) {
        const c = await nextCommand();
        const dir = c.startsWith("go-") ? c.slice(3) : c;
        if (!DIRS.has(dir)) continue;
        const f = focused();
        const pane = f?.pane && panes().find((p) => p.pane === f.pane);
        if (pane?.zoomed) run("pane.zoom", { pane: pane.pane });
        run("pane.go", { direction: dir });
      }
    });
  }

  render() {
    return div();
  }
}
