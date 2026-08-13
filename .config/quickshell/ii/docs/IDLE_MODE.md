# IDLE Mode

IDLE mode is a single full-screen layer-shell overlay, visually related to the boot greeting but intended to stay useful while the user is away. It appears after 3 minutes of inactivity by default, or immediately with `Super+Shift+I`. Pressing `Enter` is the explicit return action.

## UI composition

The overlay uses a custom three-column layout whose accent and surface colors follow the active shell theme. Its full-screen surface stays transparent and relies on the compositor's live blur; it does not render a replacement wallpaper, gradient, or background tint. Theme-timed opacity/scale transitions animate both entry and exit; compositor animation is disabled for this layer to avoid a second cached-shadow fade after the QML content is gone.

- Left: weather, system pipeline, and a custom MPRIS player.
- Center: oversized weekday/date/time, user avatar, name, and the Enter-to-exit prompt.
- Right: an interactive month calendar, the selected day's event count, and session activity.
- Bottom: the live CAVA spectrum while media is playing, with a low-power ambient pulse otherwise.

Notification content, clipboard history, calendar event titles, and other private text are deliberately excluded.

Pointer controls remain available while the keyboard guard is active. Calendar
days can be selected and the `+` action opens the normal event editor with that
date pre-filled. The Network activity row opens the normal Wi-Fi picker, including
scan and connect actions. While either dialog is open, the overlay pauses its
focus heartbeat so text fields and dialog controls retain keyboard focus.

`cava` is the optional runtime behind the live spectrum. If it is unavailable or has not produced samples yet, the overlay keeps the ambient spectrum moving instead of rendering a dead line.

## Lifecycle

1. `services/Idle.qml` starts `swayidle` with the configured `idle.idleModeTimeout` (180 seconds by default).
2. The timeout invokes `inir idle open`; the same overlay can be toggled through the Hyprland global shortcut.
3. On Hyprland, opening the overlay activates the dedicated `idle` submap, removing workspace/window/app compositor binds.
4. The overlay takes exclusive keyboard focus. Return/Keypad Enter dismisses it; media next/previous/play-pause keys remain available, and every other dashboard keyboard event is consumed. Interactive IDLE dialogs receive normal text input while open.
5. Closing IDLE resets the Hyprland submap; destruction and lock transitions also run the reset as fail-safe cleanup.
6. Locking the session always closes IDLE mode so the lock surface owns focus.
7. Existing screen-off, lock, and suspend timers continue independently for power saving and security.

## Recommended follow-ups

- Multi-monitor policy setting: primary-only (current), mirrored, or one dashboard plus wallpaper-only companion screens.
- Burn-in protection for OLED: shift the hero group a few pixels every several minutes.
- Focus timer/Pomodoro status as another opt-in glance card.
- A reduced-power profile that disables blur and graph animation on battery.
