# Ankh DE

**Windows 11 geometry. Ankh colours. On KDE Plasma 6.**

*[Version française](README.md) — the project's primary language is French; this file is
maintained in English because the people who would install this don't all read French.*

Ankh DE gives Plasma the metrics, typography, materials, motion and shell layout of Windows 11 —
to the pixel, and **checked by a program** — in the graphite-and-violet identity of
[Ankh](https://github.com/PatrickChoumi/Ankh). It installs on Fedora, Arch or Ubuntu without
modifying a single file belonging to your distribution, and it uninstalls in one command.

> ### Status: pre-release — the taskbar and Start menu are ours, and it is proven.
>
> Ankh DE has been **installed by its own installer in a fresh VM** (Fedora 44, Plasma 6.8.2)
> and the session opened **from the login screen**. Inside it: `ANKH_DE_SESSION=1`, style
> `Ankh`, colours `Ankh`, font `Selawik 10.5`, decoration `org.ankh.decoration`, icons
> `Fluent-Ankh`, Plasma style `ankh`, Selawik found by fontconfig, and **48 key-by-key checks**
> passing *inside the session*.
>
> **The Start menu opens.** Three independent proofs, because one is not enough:
>
> | Question | What the run answers |
> |---|---|
> | Which layout did `plasmashell` evaluate? | `…/org.ankh.de.desktop/…/org.kde.plasma.desktop-layout.js` — **ours**, from its own log |
> | What is in the bar? | `org.ankh.demarrer`, `org.ankh.horloge`, `org.ankh.bureau` installed; `icontasks` and the system tray stay Plasma's, by deliberate fallback |
> | Did the screen change on open? | **9.33 %** of it, a 662×694 box at x=314 of 1280 — **centred**, not pinned left like Kickoff |
>
> Until 2026-11-06 the visible bar was **Breeze's**, wearing our colours, icons and Plasma
> theme: `kdeglobals [KDE] LookAndFeelPackage` was written nowhere ([DE-014](DECISIONS.md),
> French). That disguise kept the fault hidden for days, and three of the harness's own checks
> printed "FAILED" inside a green run. Both are fixed.
>
> Metrics for batches 1–3 are **measured in a VM on Fedora 44**: 32 px title bar, `#C42B1C`
> close button at 46×32, 8.2 px corners, 32 px controls, 40×20 toggle, 12 px scrollbar, Selawik
> at 14 px. **27 of 53 tokens measured and conforming** — 12 controls, 6 windows, and **all 9 for the bar**, measured in a VM on `fbe7f47`, where Build, Bench and VM **all pass on the same SHA**.
> Still unproven: the installer on Arch and Ubuntu, and the Arch and Debian packages.
> What is verified and what is not: [AVANCEMENT.md](AVANCEMENT.md) (French).

![Ankh DE's Start menu, open in a VM](docs/images/demarrer-vm.png)

## What it is

| | |
|---|---|
| **Widget style** | A Qt 6 `QStyle` derived from Breeze: 4 and 8 px radii, 32 px buttons and fields, thin scrollbars, two-line focus ring, to WinUI metrics |
| **Window decoration** | A KDecoration3 plugin: 32 px title bar, title on the left, 46×32 buttons, `#C42B1C` close on hover, 8 px corners, Windows 11 shadows |
| **Global theme** | `org.ankh.de.desktop` — carries every default, with the stuck 48 px taskbar as an opt-in |
| **Colours** | Windows 11's greys rendered as Ankh's blue-tinted graphite, layered, dark and light. The accent follows the wallpaper, like Windows 11's "Automatic" accent |
| **Font** | [Selawik](https://github.com/microsoft/Selawik), the free Segoe UI lookalike Microsoft published under OFL 1.1, built from source |
| **Cursors and icons** | [Fluent](https://github.com/vinceliuice/Fluent-icon-theme) (GPL-3.0), recoloured to Ankh's violet |
| **GTK apps** | [Fluent-gtk-theme](https://github.com/vinceliuice/Fluent-gtk-theme) (GPL-3.0), in Ankh's violet |
| **Measurement bench** | 53 measurements, each with its Windows 11 target, tolerance and source. A deviation fails CI |

## What it is not

- **Not a desktop environment written from scratch.** It replaces neither the compositor, nor the
  session manager, nor `plasmashell`. It is a theme and applet suite for Plasma 6.
- **Not a Windows 11 clone.** The metrics are Windows'; the colours are Ankh's.
- **Not a Microsoft product, and unaffiliated with Microsoft.** No Windows file is shipped or
  downloaded: no font, no icon, no sound, no cursor, no wallpaper. Only the **measurements** are
  reused, from sources Microsoft publishes under the MIT licence.
- **Not a distribution.** Ankh, the OS, is personal and is not distributed. Ankh DE works without
  it.

## Install

**Requirements**: KDE Plasma **6.8.x**, Wayland session, Qt 6.6+, KDE Frameworks 6+.
Every proof in this repository is made on **6.8.2** (Fedora 44).
Plasma 6.8 is not supported yet.

```bash
git clone https://github.com/PatrickChoumi/Ankh-DE
cd Ankh-DE
./installer.sh
```

The installer tells you which packages are missing, for Fedora, Arch and Ubuntu. It builds the
style and decoration, builds the font, cursors and GTK theme from pinned upstream commits,
installs into `/usr/local`, and applies the `org.ankh.de.desktop` global theme.

**Your panels are left alone.** To also get the Windows 11 taskbar (stuck to the bottom, 48 px,
Start and apps centred) you have to ask for it, and confirm — it **wipes your current panels**:

```bash
./installer.sh --barre        # --barre means "panel"
```

To try it without root, inside your home directory (needs a re-login):

```bash
./installer.sh --utilisateur  # --user also works
```

To undo everything:

```bash
./desinstaller.sh
```

## Accepted limits

Honesty first. "Pixel-perfect" stops where Plasma stops. These **will not be fixed** until KDE
opens them up:

- the volume OSD's **contents** and the notification **width** are hard-coded in Plasma;
- **no snap-layout flyout** when hovering the maximise button — KWin has nothing for it. You get
  Super+arrows and the tile editor (Super+T);
- **libadwaita** apps (Bottles, ProtonPlus…) keep their own look: they only receive the accent
  colour, which libadwaita snaps to its own violet;
- **Chrome, VS Code and Electron apps** draw their own title bars;
- **Flatpak GTK apps** don't see the system GTK theme;
- **Start** and **quick settings** (batches 5 and 6) will use *private* Plasma modules: they can
  break on any Plasma release. CI will catch it before the update reaches you;
- Selawik has **no semibold** and incomplete kerning: a semibold heading renders bold.

## Contributing

The one rule that matters: **a claim of fidelity without a bench measurement is not accepted**.
See [CONTRIBUTING.md](CONTRIBUTING.md). Project documents are in French; issues and pull requests
in English are welcome.

Help is most useful on the recurring cost: **rebasing onto each Plasma release**
([docs/REBASE.md](docs/REBASE.md)). Plasma ships roughly twice a year, and 6.8 removes X11.

## Licence

**GPL-3.0-or-later** — not a preference but a requirement: the style and decoration derive from
[Breeze](https://invent.kde.org/plasma/breeze) (GPL-2.0-or-later), the cursors and GTK theme from
[Fluent](https://github.com/vinceliuice/Fluent-icon-theme) (GPL-3.0). Provenance and licence of
every borrowed piece is in [LICENSES/](LICENSES/).

Windows and Windows 11 are trademarks of Microsoft Corporation. This project is not affiliated
with or endorsed by Microsoft, and distributes none of its files.
