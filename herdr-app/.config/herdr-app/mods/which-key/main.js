// which-key for the ctrl+a prefix. keys.json binds a lone "ctrl-a" here; GPUI only
// runs it once the prefix has waited ~1s with no second key, so fast combos never
// see this popup. It lists every "ctrl-a <key>" binding from keys.json and runs
// the one whose key is pressed next. Esc (or any unbound key) cancels.

import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { keys, commands, focused, run, hc, theme, props, closeOverlay } from "herdr";

const PREFIX = "ctrl-a ";
const LABEL = {
  "tab.new": "new tab",
  "tab.next": "next tab",
  "tab.prev": "previous tab",
  "tab.rename": "rename tab",
  "space.rename": "rename space",
  "pane.split:down": "split down",
  "pane.split:right": "split right",
  "pane.close": "close pane",
  "pane.zoom": "zoom pane",
  "pane-nav.go-left": "pane left",
  "pane-nav.go-down": "pane down",
  "pane-nav.go-up": "pane up",
  "pane-nav.go-right": "pane right",
  "mod.open:my-picker": "picker",
  "layout.toggle:sidebar": "toggle sidebar",
  "tab.close": "close tab",
  "space.close": "close space",
  "space.next": "next space",
  "space.prev": "previous space",
  "pane.swap:right": "swap pane right",
  "pane.swap:left": "swap pane left",
  "prefix-keys.tab-right": "move tab right",
  "prefix-keys.tab-left": "move tab left",
  "agent.next": "next agent",
  "agent.prev": "previous agent",
  "terminal.search": "search scrollback",
  "prefix-keys.copy": "copy mode (nvim)",
  "prefix-keys.last-space": "last space",
  "prefix-keys.files": "files panel",
  "prefix-keys.changes": "changes panel",
  "app.palette": "command palette",
  "app.help": "keys help",
  "layout.switch": "switch layout",
  "send:\u0001": "send ctrl-a",
  "send:\u000c": "clear screen",
};
const label = (action) => {
  if (typeof action !== "string") return action?.command ?? "?";
  if (LABEL[action]) return LABEL[action];
  const m = action.match(/^tab\.select:(\d+)$/);
  return m ? `tab ${m[1]}` : action;
};
const show = (k) => k.replace(/^ctrl-/, "^");

export default class WhichKey extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.timer.after(50, () => this.handle.focus());
  }

  // The second key of every ctrl+a combo, in keys.json order (global, then terminal).
  bindings() {
    const out = new Map();
    for (const b of keys()) {
      if (!b.keys.startsWith(PREFIX)) continue;
      const k = b.keys.slice(PREFIX.length);
      if (!k.includes(" ") && !out.has(k)) out.set(k, b.action);
    }
    return out;
  }

  close() {
    closeOverlay(props().overlay);
  }

  perform(action) {
    this.close();
    if (action && typeof action === "object") return run(action.command, action.args ?? {});
    if (typeof action !== "string" || action === "terminal") return;
    if (action.startsWith("send:")) {
      const terminal = focused()?.terminal;
      if (!terminal) return;
      const presses = [...action.slice(5)].map((ch) => {
        const c = ch.charCodeAt(0);
        return c > 0 && c < 27 ? `ctrl+${String.fromCharCode(c + 96)}` : ch;
      });
      hc(["keys", terminal, ...presses]);
      return;
    }
    const i = action.indexOf(":");
    if (i < 0) return run(action);
    // "name:value" fills the command's first argument, as keys.json does.
    const name = action.slice(0, i);
    const value = action.slice(i + 1);
    const arg = commands().find((c) => c.name === name)?.args?.[0]?.name;
    run(name, arg ? { [arg]: /^\d+$/.test(value) ? Number(value) : value } : {});
  }

  render() {
    const t = theme();
    const map = this.bindings();
    // tab.select:1..9 collapse into one "1-9" row; four columns of the rest.
    const items = [];
    let digits = false;
    for (const [k, action] of map) {
      if (/^[1-9]$/.test(k) && /^tab\.select:\d+$/.test(action)) {
        if (!digits) items.push({ k: "1-9", text: "go to tab 1-9" });
        digits = true;
      } else items.push({ k, text: label(action) });
    }
    const per = Math.ceil(items.length / 4) || 1;
    const columns = [0, 1, 2, 3].map((c) => items.slice(c * per, (c + 1) * per));
    const row = (it) =>
      h_flex().gap(8).items_center().h(24)
        .child(div().min_w(34).px(6).py(1).rounded(4).bg(t.raised).text_color(t.accent).font_family("JetBrains Mono").text_size(12).child(show(it.k)))
        .child(div().text_color(t.dim).child("→"))
        .child(div().text_color(t.foreground).truncate().child(it.text));

    return v_flex()
      .id("which-key")
      .track_focus(this.handle)
      .size_full()
      .p(16)
      .gap(12)
      .bg(t.popover)
      .text_size(13)
      .on_key_down((e, cx) => {
        cx.stop_propagation();
        if (e.key === "escape") return this.close();
        // Typed characters ("$", "|", "_") match by what they type; chords by their spelling.
        const typed = e.modifiers.control || e.modifiers.alt || e.modifiers.platform ? null : e.key_char;
        const action = (typed && map.get(typed)) ?? map.get(e.keystroke) ?? map.get(e.key);
        if (action !== undefined) this.perform(action);
        else this.close();
      })
      .child(
        h_flex().items_center().gap(10)
          .child(div().px(8).py(2).rounded(5).bg(t.accent).text_color(t.accent_foreground).font_family("JetBrains Mono").text_size(12).child("^a"))
          .child(div().text_color(t.muted).child("waiting for the next key…"))
          .child(div().flex_1())
          .child(div().text_color(t.dim).text_size(11).child("esc to cancel")),
      )
      .child(
        h_flex().gap(24).items_start()
          .children(columns.map((col, i) => v_flex().id(`col-${i}`).flex_1().min_w(0).gap(2).children(col.map(row)))),
      );
  }
}
