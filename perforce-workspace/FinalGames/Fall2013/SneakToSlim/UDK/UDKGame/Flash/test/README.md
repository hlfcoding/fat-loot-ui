# Main Menu

`MainMenu.fla` is the main Flash Editor file that manually exports to its
namesake SWF file, as well as `MainMenu_Preview.swf`. The latter is exported
with the `MainMenuView.DEBUG` and `MainMenuView.USE_FIXTURES` flags on and the
`MainMenuView.SEND_COMMANDS` flag off, so it can be used as a standalone
application, outside of the game.

The FLA file links together the static assets in `/Assets` and the dynamic
assets in `/MainMenu` with AS classes. It loads `CLIK_Components_AS3.fla`.
It configures and lays out each screen and its subviews and links them to their
respective AS classes.
