# nixos-config

The NixOS and Home Manager configuration for these hosts and their users.

## Desktop

**Desktop session**:
What the user gets after logging in: keybinds, startup apps, where windows open, and monitor layout, independent of the window manager.
_Avoid_: WM config, niri config

**Window manager adapter**:
The aspect that turns the desktop session into one window manager's config and session command.
_Avoid_: WM module

**Background startup**:
An app started at login on a non-home workspace without taking focus.
_Avoid_: autostart workspace
