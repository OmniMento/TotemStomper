# TotemStomper WoW Addon

TotemStomper is a utility addon for Shamans that manages totem sets through a customizable UI and an automated `/castsequence` macro. It is compatible with both Classic Era and The Burning Crusade.

---

## Features

### Four Customizable Totem Buttons

The addon displays four configurable totem buttons representing your active totem set. Each button can be enabled, disabled, or reassigned individually.

---

### Filtered Totem Selection

Right-clicking a button opens a dropdown menu categorized by element:

- Earth
- Fire
- Water
- Air

The menu only shows totems available to your character based on:

- Level
- Game version
- Active talents such as Mana Tide Totem or Totem of Wrath

---

### Macro Generation

TotemStomper automatically creates and updates a global macro named `TotemStomper`.

The macro:

- Includes all enabled totems
- Supports a configurable reset timer between `6` and `30` seconds
- Automatically skips disabled totems in the generated sequence

---

### Interactive UI

| Action | Result |
|---|---|
| **Left-Click** | Enable or disable a totem |
| **Right-Click** | Change the assigned totem for that slot |
| **Disabled Totems** | Displayed with reduced opacity |
| **Cooldown Timers** | Shows remaining duration directly on each button |

---

### Drag-and-Drop Positioning

The frame can be dragged and positioned anywhere on the screen.

Use **Shift + Right-Click** on the anchor to:

- Lock or unlock movement
- Hide the drag handle when not needed

---

### Version Validation

On login, the addon validates saved spell data against the current game version to prevent invalid spell assignments when switching between Classic Era and TBC characters.

---

### Settings Menu

Configuration options are available through the standard Blizzard Interface Options panel, including:

- Duration text display
- Movement locking
- Macro reset interval