// Pick a space. Opens as a centred dialog, as tall as its rows up to 80% of the window. Spaces are
// grouped by machine (this computer first, then each remote one), each with its agents as dots on
// the right, boxed per tab like the top bar's. Type to filter, ↑/↓ and Enter to go, Esc to leave.
// A filter that matches no space offers a new space by that name. ctrl+g lists agents instead, by
// status (needs you, done, working, idle) with their sub-agents under them; ctrl+x lists zoxide's
// folders (picking one opens a new space there, like sesh). The same key again goes back to spaces.
// ctrl+d closes the selected space (Herdr asks first). The first rows you can pick carry a letter
// (^s, ^l, ...): ctrl+<letter> goes straight there.

import { View, div, svg, image } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { agents, spaces, machines, panes, terminals, run, exec, home, appHome, readTextFile, theme, settings, props, closeOverlay, shared, setShared } from "herdr";

const PICK = new Set(["space", "create", "agent", "sub", "dir"]);
const MODES = { g: "agents", x: "zoxide" };
// Jump letters, in order. Not the picker's own keys (j k w g x d), not ctrl+a (the prefix),
// and not the emacs keys the search field may use (a b e f h k n p t v y o).
const JUMP = ["s", "l", "r", "u", "c", "q", "z", "i", "m"];
const H = { machine: 30, space: 32, create: 32, section: 30, agent: 32, sub: 26, dir: 32 };

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

// Agents by status, as the agents sidebar sorts them. A sub-agent without a pane reports to its
// parent: its error counts as blocked, its done as idle (the parent's done is the news).
const RANK = { blocked: 4, done: 3, working: 2, idle: 1 };
const SECTION = { 4: "Needs you", 3: "Done", 2: "Working", 1: "Idle" };
const SECTION_STATUS = { 4: "blocked", 3: "done", 2: "working" };
const kidStatus = (k, listed) => {
  const s = listed.get(k.address) ?? k.status;
  return s === "error" ? "blocked" : s === "done" ? "idle" : s;
};

function duration(ms) {
  const m = Math.floor(ms / 60000);
  if (m < 1) return "<1m";
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
}

// The program's icon from the app's table: a one-color glyph or a picture.
function icon(p, size, color) {
  if (!p?.icon) return null;
  return p.tint ? svg(p.icon).size(size).flex_none().text_color(color) : image(p.icon).w(size).h(size).flex_none();
}

const base = (path) => (path ?? "").replace(/\/+$/, "").split("/").pop();
const clean = (s) => (s ?? "").replace(/^[^\p{L}\p{N}]+/u, "").trim();

// Runs of the same key in an ordered list (agents() comes in space, tab, pane order).
const runs = (xs, key) => xs.reduce((out, x) => {
  const last = out[out.length - 1];
  if (last && key(last[0]) === key(x)) last.push(x); else out.push([x]);
  return out;
}, []);

export default class Picker extends View {
  init(_props, cx) {
    this.filter = "";
    this.input = InputState.new({ placeholder: "Go to a space…" });
    this.input.on("change", (_e, cx) => { this.filter = this.input.value(); this.at = 0; cx.notify(); });
    this.input.on("submit", () => this.go(this.rows().filter((r) => PICK.has(r.kind))[this.at]));
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    this.at = null;
    this.scroll = 0;
    this.dirs = [];
    this.mode = "spaces";
    this.changed = {};
    this.handle = cx.focus_handle();
    cx.spawn(async (cx) => {
      // When each agent last changed state, as the agents sidebar keeps it.
      try {
        const store = JSON.parse((await readTextFile(`${appHome()}/data/agents/store.json`)) ?? "{}");
        this.changed = JSON.parse(store.changed ?? "{}");
      } catch {}
      // zoxide's folders, most frecent first (Finder launches may lack Homebrew on PATH).
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
    if (this.mode === "zoxide") return this.dirRows(f);
    if (this.mode === "agents") return this.agentRows(f);
    return this.spaceRows(f);
  }

  // Spaces under a header per machine: this computer, then the others by name.
  spaceRows(f) {
    const sp = spaces();
    const ps = panes();
    const all = agents();
    const remote = [...new Set([...sp.map((s) => s.machine), ...machines().map((m) => m.name)].filter(Boolean))].sort();
    const out = [];
    for (const m of [null, ...remote]) {
      const mine = sp
        .filter((s) => (s.machine ?? null) === m)
        .map((s) => {
          // Where it is now: its first terminal's folder. Shown when the name doesn't say it.
          const tabs = new Set(s.tabs.map((c) => c.id));
          const cwd = ps.find((p) => tabs.has(p.tab) && p.cwd)?.cwd || s.folder;
          const branch = s.branch && !["main", "master"].includes(s.branch) && s.branch !== s.name ? s.branch : "";
          const folder = base(cwd) && base(cwd) !== s.name && base(cwd) !== base(home()) ? base(cwd) : "";
          return { kind: "space", s, tail: branch || folder, mine: all.filter((a) => a.space === s.id) };
        })
        .filter((r) => !f || [r.s.name, r.tail, m ?? "this computer"].join(" ").toLowerCase().includes(f));
      if (f && !mine.length) continue;
      const ready = machines().find((k) => k.name === m)?.layout;
      out.push({ kind: "machine", m, up: !m || ready === "ready" }, ...mine);
    }
    // Nothing matches: Enter makes a space with that name.
    const name = this.filter.trim();
    if (name && !out.some((r) => r.kind === "space")) out.push({ kind: "create", name });
    return out;
  }

  // Agents in sections by status, most urgent first; each with its live sub-agents under it.
  agentRows(f) {
    let list = agents();
    const all = terminals();
    const listed = new Map(list.map((a) => [a.address, a.status]));
    const tree = (addr, lead = []) => {
      const kids = all.filter((k) => k.parent === addr && k.state === "live");
      return kids.flatMap((k, i) => {
        const last = i === kids.length - 1;
        return [{ k, lines: [...lead, last ? "└" : "├"] }, ...tree(k.address, [...lead, last ? "" : "│"])];
      });
    };
    // A kept sub-agent (with a pane) shows under its parent, not as a row of its own.
    const nested = new Set(list.flatMap((a) => tree(a.address).map((s) => s.k.address)));
    list = list.filter((a) => !nested.has(a.address));
    const tabs = new Map(spaces().flatMap((s) => s.tabs).map((c) => [c.id, c]));
    const since = (a) => this.changed[a.address]?.at ?? tabs.get(a.tab)?.changed_at ?? 0;
    const urgency = new Map(list.map((a) => [a.address, Math.max(RANK[a.status] ?? 0, ...tree(a.address).map((s) => RANK[kidStatus(s.k, listed)] ?? 0))]));
    list.sort((x, y) => urgency.get(y.address) - urgency.get(x.address) || since(y) - since(x) || y.seq - x.seq);
    const out = [];
    let section = null; // the current section's row; its count grows as agents land in it
    for (const a of list) {
      // "space · detail": a tab someone named, else the agent's own title.
      const tab = tabs.get(a.tab);
      const title = clean(a.title);
      const detail = tab?.named ? tab.name : title && title !== a.program?.name && !/^[~/]/.test(title) ? title : "";
      const machine = a.address.includes("/") ? a.address.split("/")[0] : null;
      const subs = tree(a.address);
      const text = [a.space_name, detail, machine ?? "", ...subs.map((s) => s.k.name ?? "")].join(" ").toLowerCase();
      if (f && !text.includes(f)) continue;
      const r = urgency.get(a.address) || RANK.idle;
      if (r !== section?.rank) out.push(section = { kind: "section", rank: r, label: SECTION[r], status: SECTION_STATUS[r], count: 0 });
      section.count++;
      out.push({ kind: "agent", a, detail, machine, when: since(a), subs: subs.length });
      for (const s of subs) out.push({ kind: "sub", ...s, status: kidStatus(s.k, listed), listed: listed.has(s.k.address) });
    }
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
    if (r.kind === "space") run("space.select", { id: r.s.id });
    else if (r.kind === "agent") run("pane.focus", { pane: r.a.pane });
    else if (r.kind === "sub") run(r.listed ? "pane.focus" : "terminal.peek", { terminal: r.k.address });
    else if (r.kind === "create") run("space.new", { name: r.name, machine: "" });
    else if (r.kind === "dir") run("space.new", { folder: r.folder, machine: "" });
  }

  // As the agents sidebar draws a status: a spinner, a "Needs you" pill, a dot for done, a ring for idle.
  status(t, st) {
    if (st === "working") return svg("mods/workspace-chrome/spinner.svg").size(12).mx(1).flex_none().text_color(t.working).spin(900);
    if (st === "blocked") return div().flex_none().px(6).h(18).rounded(5).bg(t.blocked + "26").text_size(10.5).font_semibold().text_color(t.blocked).flex().items_center().child("Needs you");
    if (st === "idle") return div().size(7).mx(3).flex_none().rounded(4).border(1.5).border_color(t.idle ?? t.dim);
    return div().size(7).mx(3).flex_none().rounded(4).bg(st === "done" ? t.done : t.dim + "00");
  }

  // A space's agents as dots coloured by status, boxed per tab when a tab has 2+, as in the top bar.
  dots(t, mine) {
    const dot = (a) => div().size(8).rounded(4).bg(t[a.status] ?? t.dim);
    const tab = (group) => {
      const row = h_flex().gap(5).items_center().children(group.map(dot));
      return group.length < 2 ? row : row.px(4).py(3).rounded(5).border(1).border_color(t.border).bg(t.hover);
    };
    return h_flex().flex_none().gap(6).items_center().children(runs(mine, (a) => a.tab).map(tab));
  }

  render() {
    const t = theme();
    const rows = this.rows();
    const pickable = rows.filter((r) => PICK.has(r.kind));
    // Opens on where you are.
    if (this.at === null) this.at = Math.max(0, pickable.findIndex((r) => (r.kind === "space" && r.s.active) || (r.kind === "agent" && r.a.focused)));
    this.at = Math.max(0, Math.min(this.at, pickable.length - 1));
    const sel = pickable[this.at];
    const now = Date.now();
    // One continuous strip: each row (and the group title before it) at a fixed
    // y. Scrolling moves the strip only as far as it takes to keep the selected
    // row in view, so the arrows can't run the selection off the list.
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
    // A row you can pick: highlighted when selected, Enter or a click goes.
    const item = (r, id) => h_flex().id(id).mx(4).px(10).h(H[r.kind]).flex_none().items_center().rounded(7).gap(10).cursor_pointer()
      .when(r === sel, (el) => el.bg(t.hover)).hover((s) => s.bg(t.hover)).on_click(() => this.go(r));

    const row = (r) => {
      if (r.kind === "machine") {
        return h_flex().h(H.machine).px(10).pt(8).gap(8).items_center().text_size(11).text_color(t.dim)
          .child(svg(`mods/workspace-chrome/${r.m ? "server" : "monitor"}.svg`).size(13).flex_none())
          .child(div().flex_1().truncate().child(r.m ?? "This computer"))
          .child(div().size(6).rounded(3).flex_none().mr(30).bg(r.up ? t.ansi2 : t.dim));
      }
      if (r.kind === "section") {
        return h_flex().h(H.section).px(10).pt(8).gap(6).items_center().text_size(11).font_medium()
          .child(div().text_color(t[r.status] ?? t.dim).child(r.label))
          .child(div().text_color(t.dim).child(String(r.count)));
      }
      if (r.kind === "space") {
        return item(r, `pk-${r.s.id}`)
          .child(h_flex().size(18).flex_none().rounded(5).bg(spaceColor(t, r.s)).items_center().justify_center().text_size(10.5).font_bold().text_color("#ffffff").child([...r.s.name][0]?.toUpperCase() ?? "?"))
          .child(div().flex_shrink(0).max_w(220).truncate().text_color(t.foreground).when(r.s.active, (d) => d.font_semibold()).child(r.s.name))
          .child(div().flex_1().min_w(0).truncate().text_size(11.5).text_color(t.dim).child(r.tail))
          .child(this.dots(t, r.mine))
          .child(cap(r));
      }
      if (r.kind === "agent") {
        const a = r.a;
        const idle = a.status === "idle" && !a.focused;
        return item(r, `pk-ag-${a.address}`)
          .child(icon(a.program, 16, t.foreground) ?? div().w(16).flex_none())
          .child(h_flex().flex_1().min_w(0).gap(5).items_center()
            .child(div().flex_shrink(0).max_w(220).truncate().text_color(idle ? t.muted : t.foreground).when(a.focused, (d) => d.font_semibold()).child(a.space_name))
            .when(Boolean(r.detail), (el) => el.child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(`· ${r.detail}`))))
          .when(Boolean(r.machine), (el) => el.child(div().flex_none().text_size(10.5).text_color(t.dim).child(r.machine)))
          .when(Boolean(r.when), (el) => el.child(div().flex_none().text_size(11).text_color(t.dim).child(duration(now - r.when))))
          .child(this.status(t, a.status))
          .child(cap(r));
      }
      if (r.kind === "sub") {
        return item(r, `pk-sub-${r.k.address}`).gap(0).text_size(12.5)
          .child(div().w(16).mr(10).flex_none())
          .children(r.lines.map((l) => div().self_start().mt(-4).w(9).h(17).mr(4).flex_none()
            .when(Boolean(l), (el) => el.border_l(1.5).border_color(t.input))
            .when(l === "└" || l === "├", (el) => el.border_b(1.5).rounded_bl(6))))
          .child(div().mr(8).child(icon(r.k.program, 14, t.foreground) ?? svg("mods/workspace-chrome/terminal.svg").size(14).text_color(t.muted)))
          .child(div().flex_1().truncate().text_color(t.muted).child(r.k.name || r.k.template || r.k.program?.name || r.k.address))
          .child(div().mr(10).child(this.status(t, r.status)))
          .child(cap(r));
      }
      if (r.kind === "dir") {
        return item(r, `pk-dir-${r.folder}`)
          .child(svg("mods/workspace-chrome/folder.svg").size(12).flex_none().text_color(t.ansi4))
          .child(div().flex_1().truncate().text_color(t.foreground).child(r.label))
          .child(cap(r));
      }
      return item(r, "pk-create").gap(8).text_color(t.muted)
        .child(div().w(18).flex_none().flex().justify_center().child("+"))
        .child(div().flex_1().truncate().child(`new space "${r.name}"`))
        .child(cap(r));
    };

    const title = { spaces: "Spaces", agents: "Agents", zoxide: "Folders" }[this.mode];
    const hint = this.mode === "spaces"
      ? "^letter jump  ^j/^k move  ^g agents  ^x zoxide  ^d close  ·  Esc"
      : `^letter jump  ^j/^k move  ^${this.mode === "agents" ? "g" : "x"} spaces  ·  Esc`;

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
          if (sel?.kind === "space") {
            this.close();
            run("space.close", { id: sel.s.id });
          }
        } else if (e.modifiers.control && (MODES[k] || k === "w")) {
          this.mode = this.mode === MODES[k] || k === "w" ? "spaces" : MODES[k];
          this.at = null;
          this.scroll = 0;
        } else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child(title))
        .child(div().text_size(11).text_color(t.dim).child(hint)))
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
