// Go to a tab or a folder. Opens as a centred dialog, as tall as its rows up to 80% of the window. Every
// space is in one list, those with something that needs you first. Type to
// filter, ↑/↓ and Enter to go, ctrl+d to close a tab, Esc to leave. A filter
// that matches no tab offers a new space by that name. ctrl+w / ctrl+g
// show only spaces / agents; ctrl+x shows only zoxide's folders (picking one
// opens a new space there, like sesh). The same key again shows everything.
// The first rows you can pick carry a letter (^s, ^l, ...): ctrl+<letter> goes straight there.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { agents, spaces, terminals, run, exec, home, theme, settings, props, closeOverlay, openOverlay, shared, setShared } from "herdr";

const PICK = new Set(["ctx", "create", "dir"]);
const MODES = { w: "spaces", g: "agents", x: "zoxide" };
// Jump letters, in order. Not the picker's own keys (j k w g x d), not ctrl+a (the prefix),
// and not the emacs keys the search field may use (a b e f h k n p t v y o).
const JUMP = ["s", "l", "r", "u", "c", "q", "z", "i", "m"];

const MARK = { ansi6: "#22a99a", ansi3: "#e3814f", ansi4: "#5b8def", ansi5: "#8b7cf6", ansi2: "#3fae6a", ansi1: "#d9649a" };

// Space colors, kept by space id in shared "space.colors": a theme
// color name ("ansi6") or a picked #rrggbb. A space seen without one gets
// the theme color fewest spaces use, once; every mod does the same in the
// same order, so they agree, and adding or renaming spaces moves nothing.
const PROJECT_COLORS = ["ansi6", "ansi3", "ansi4", "ansi5", "ansi2", "ansi1"];
function spaceColors() {
  const ids = new Set(spaces().map((p) => p.id));
  const kept = Object.fromEntries(Object.entries(shared("space.colors") ?? {}).filter(([id]) => ids.has(id)));
  let changed = Object.keys(kept).length !== Object.keys(shared("space.colors") ?? {}).length;
  for (const p of spaces()) {
    if (kept[p.id] || p.name === "~") continue;
    const uses = (c) => Object.values(kept).filter((v) => v === c).length;
    kept[p.id] = PROJECT_COLORS.reduce((best, c) => (uses(c) < uses(best) ? c : best));
    changed = true;
  }
  if (changed) setShared("space.colors", kept);
  return kept;
}
function spaceColor(t, p) {
  if (p.name === "~") return t.dim;
  const c = spaceColors()[p.id] ?? PROJECT_COLORS[0];
  return c.startsWith("#") ? c : (MARK[c] ?? t[c]);
}

export default class Picker extends View {
  init(_props, cx) {
    this.filter = "";
    this.input = InputState.new({ placeholder: "Go to a tab, space, agent or folder…" });
    this.input.on("change", (_e, cx) => { this.filter = this.input.value(); this.at = 0; cx.notify(); });
    this.input.on("submit", () => this.go(this.rows().filter((r) => PICK.has(r.kind))[this.at]));
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    this.at = null;
    this.scroll = 0;
    this.dirs = [];
    this.mode = "all";
    this.handle = cx.focus_handle();
    // zoxide's folders, most frecent first (Finder launches may lack Homebrew on PATH).
    cx.spawn(async (cx) => {
      for (const z of ["zoxide", "/opt/homebrew/bin/zoxide"]) {
        try {
          const r = await exec(z, ["query", "-l"]);
          if (r.code === 0) { this.dirs = r.stdout.split("\n").filter(Boolean); break; }
        } catch {}
      }
      cx.notify();
    });
  }

  close() {
    closeOverlay(props().overlay);
  }

  rows() {
    const f = this.filter.toLowerCase();
    const all = agents();
    const live = terminals().filter((x) => x.state === "live");
    const teamOf = (addrs) => {
      let n = 0;
      const walk = (a) => live.filter((x) => x.parent === a).forEach((k) => (n++, walk(k.address)));
      addrs.forEach(walk);
      return n;
    };
    const mode = this.mode;
    const groups = mode === "zoxide" ? [] : spaces().map((w) => {
      const ctxs = w.tabs
        .map((ctx) => {
          const mine = all.filter((a) => a.tab === ctx.id);
          return { w, ctx, mine, team: teamOf(mine.map((a) => a.address)) };
        })
        .filter((c) => mode !== "agents" || c.mine.length)
        .filter((c) => !f || [w.name, c.ctx.name, ...c.mine.map((a) => a.program?.name ?? "")].join(" ").toLowerCase().includes(f));
      return { w, ctxs };
    });
    const shown = groups.filter((p) => p.ctxs.length);
    shown.sort((a, b) => (b.w.status === "blocked") - (a.w.status === "blocked"));
    const out = [];
    for (const p of shown) {
      out.push({ kind: "head", w: p.w });
      for (const c of p.ctxs) out.push({ kind: "ctx", ...c });
    }
    if (mode === "zoxide") return this.dirRows(f);
    // Nothing matches in the spaces view: Enter makes a space with that name.
    const name = this.filter.trim();
    if (mode !== "agents" && name && !out.length) out.push({ kind: "create", name });
    return out;
  }

  dirRows(f) {
    // Every word of the filter must appear in the path, in any order.
    const words = f.split(/\s+/).filter(Boolean);
    const h = home();
    return this.dirs
      .map((d) => ({ kind: "dir", folder: d, label: d.startsWith(h) ? "~" + d.slice(h.length) : d }))
      .filter((r) => words.every((w) => r.label.toLowerCase().includes(w)));
  }

  go(r) {
    if (!r) return;
    this.close();
    if (r.kind === "ctx") run("tab.select", { id: r.ctx.id });
    else if (r.kind === "create") run("space.new", { name: r.name, machine: "" });
    else if (r.kind === "dir") run("space.new", { folder: r.folder, machine: "" });
  }

  glyph(t, st) {
    if (st === "working") return svg("mods/workspace-chrome/spinner.svg").size(12).flex_none().text_color(t.working).spin(900);
    return div().w(12).flex_none().text_color(t[st] ?? t.dim).child(st === "idle" ? "○" : st ? "●" : "·");
  }

  render() {
    const t = theme();
    const rows = this.rows();
    const pickable = rows.filter((r) => PICK.has(r.kind));
    // Opens on where you are.
    if (this.at === null) this.at = Math.max(0, pickable.findIndex((r) => r.kind === "ctx" && r.w.active && r.ctx.active));
    this.at = Math.max(0, Math.min(this.at, pickable.length - 1));
    const sel = pickable[this.at];
    // One continuous strip: each row (and the group title before it) at a fixed
    // y. Scrolling moves the strip only as far as it takes to keep the selected
    // row in view, so the arrows can't run the selection off the list.
    const H = { head: 29, ctx: 32, create: 32, dir: 32 };
    const tops = [];
    let y = 0;
    rows.forEach((r) => { tops.push(y); y += H[r.kind] ?? 32; });
    const total = y;
    // Every row shows unless the dialog (80% of the window) can't fit them; then the list scrolls.
    const height = Math.min(total, this.listHeight ?? total);
    const fixed = total > height;
    const maxScroll = Math.max(0, total - height);
    this.scroll = Math.max(0, Math.min(this.scroll, maxScroll));
    const si = rows.indexOf(sel);
    if (si >= 0) {
      if (tops[si] < this.scroll) this.scroll = tops[si];
      if (tops[si] + (H[sel.kind] ?? 32) > this.scroll + height) this.scroll = tops[si] + (H[sel.kind] ?? 32) - height;
    }
    const place = (el, i) =>
      fixed
        ? el.absolute().left(0).right(0).top(tops[i] - this.scroll).bottom(height - (tops[i] + (H[rows[i].kind] ?? 32) - this.scroll))
        : el;
    const visible = (i) => !fixed || (tops[i] + (H[rows[i].kind] ?? 32) > this.scroll && tops[i] < this.scroll + height);

    // A jump letter on each of the first rows you can pick, like a key cap.
    const cap = (r) => {
      const n = pickable.indexOf(r);
      if (n < 0 || n >= JUMP.length) return div().w(26).flex_none();
      return div().w(26).flex_none().flex().justify_end().child(
        div().px(4).rounded(4).bg(t.hover).border_1().border_color(t.border).text_color(r === sel ? t.foreground : t.dim)
          .font_family("JetBrains Mono").text_size(10.5).child(`^${JUMP[n]}`));
    };
    const row = (r) => {
      if (r.kind === "head") {
        return h_flex()
          .px(10)
          .pt(10)
          .pb(3)
          .gap(8)
          .items_center()
          .text_size(11)
          .font_semibold()
          .text_color(t.dim)
          .child(h_flex().size(18).rounded(5).bg(spaceColor(t, r.w)).items_center().justify_center().text_size(10.5).font_bold().text_color("#ffffff").child([...r.w.name][0]?.toUpperCase() ?? "?"))
          .child(r.w.name);
      }
      const on = r === sel;
      if (r.kind === "dir") {
        return h_flex()
          .id(`pk-dir-${r.folder}`)
          .mx(4)
          .px(10)
          .h(32)
          .items_center()
          .rounded(7)
          .gap(10)
          .cursor_pointer()
          .when(on, (el) => el.bg(t.hover))
          .hover((s) => s.bg(t.hover))
          .on_click(() => this.go(r))
          .child(svg("mods/workspace-chrome/folder.svg").size(12).flex_none().text_color(t.ansi4))
          .child(div().flex_1().truncate().text_color(t.foreground).child(r.label))
          .child(cap(r));
      }
      if (r.kind === "create") {
        const label = `new space "${r.name}"`;
        return h_flex()
          .id("pk-create")
          .mx(4)
          .px(10)
          .h(32)
          .items_center()
          .rounded(7)
          .gap(8)
          .text_color(t.muted)
          .cursor_pointer()
          .when(on, (el) => el.bg(t.hover))
          .hover((s) => s.bg(t.hover))
          .on_click(() => this.go(r))
          .child(div().w(12).child("+"))
          .child(div().flex_1().truncate().child(label))
          .child(cap(r));
      }
      const who = r.mine.map((a) => a.program?.name ?? "agent").join(" · ");
      const here = r.w.active && r.ctx.active;
      return h_flex()
        .id(`pk-${r.ctx.id}`)
        .mx(4)
        .px(10)
.h(32)
        .rounded(7)
        .gap(10)
        .items_center()
        .cursor_pointer()
        .when(on, (el) => el.bg(t.hover))
        .hover((s) => s.bg(t.hover))
        .on_click(() => this.go(r))
        .child(this.glyph(t, r.ctx.status))
        .child(div().flex_1().truncate().text_color(t.foreground).when(here, (d) => d.font_semibold()).child(r.ctx.name))
        .when(r.ctx.status === "blocked", (el) => el.child(div().text_size(11).text_color(t.blocked).child("needs you")))
        .when(r.ctx.status === "done", (el) => el.child(div().text_size(11).text_color(t.done).child("finished")))
        .child(div().text_size(11).text_color(t.dim).child(who + (r.team ? `  +${r.team}` : "")))
        .child(cap(r));
    };

    // The dialog is a frameless 80%-of-the-window box: the panel sits centred in it, only as tall
    // as its rows; a click on the empty part of the box closes, like one beside a dialog.
    const panel = v_flex()
      .id("picker")
      .track_focus(this.handle)
      .w_full()
      .min_h(0)
      .max_h_full()
      .p(18)
      .gap(10)
      .bg(t.popover)
      .rounded(12)
      .border_1()
      .border_color(t.border)
      .shadow_lg()
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .text_size(13)
      .on_key_down((e, cx) => {
        const k = e.key;
        if (k === "escape") return this.close();
        const down = k === "down" || (k === "j" && e.modifiers.control);
        const up = k === "up" || (k === "k" && e.modifiers.control);
        if ((down || up) && !pickable.length) return;
        if (down) this.at = (this.at + 1) % pickable.length;
        else if (up) this.at = (this.at + pickable.length - 1) % pickable.length;
        else if (e.modifiers.control && JUMP.includes(k)) return this.go(pickable[JUMP.indexOf(k)]);
        else if (k === "d" && e.modifiers.control) {
          if (sel?.kind === "ctx") {
            this.close();
            run("tab.close", { id: sel.ctx.id });
          }
        } else if (e.modifiers.control && MODES[k]) {
          this.mode = this.mode === MODES[k] ? "all" : MODES[k];
          this.at = 0;
          this.scroll = 0;
        } else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child(this.mode === "all" ? "Go to…" : `Go to… ${this.mode}`))
        .child(div().text_size(11).text_color(t.dim).child("^letter jump  ^j/^k move  ^w spaces  ^g agents  ^x zoxide  ·  Esc")))
      .child(
        h_flex().h(36).flex_none().px(10).gap(8).items_center().rounded(9).border_1().border_color(t.accent).bg(t.background)
          .child(svg("mods/workspace-chrome/search.svg").size(15).text_color(t.dim))
          .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground)),
      )
      .child(
        v_flex()
          .id("pk-list")
          .on_size_change((size, cx) => {
            this.listHeight = size.height / settings().zoom;
            cx.notify();
          })
          .h(total)
          .min_h(0)
          .mb(6)
          .when(fixed, (el) =>
            el.overflow_hidden().on_scroll_wheel((e, cx) => {
              this.scroll = Math.max(0, Math.min(this.scroll - e.delta.y, maxScroll));
              // The selection follows the wheel, so the next frame doesn't scroll back to it.
              while (this.at < pickable.length - 1 && tops[rows.indexOf(pickable[this.at])] < this.scroll) this.at++;
              while (this.at > 0 && tops[rows.indexOf(pickable[this.at])] + (H[pickable[this.at].kind] ?? 32) > this.scroll + height) this.at--;
              cx.notify();
            }))
          .children(rows.map((r, i) => (visible(i) ? place(row(r), i) : null)).filter(Boolean)),
      );
    return v_flex().id("picker-box").size_full().justify_center().on_mouse_down("left", () => this.close()).child(panel);
  }
}
