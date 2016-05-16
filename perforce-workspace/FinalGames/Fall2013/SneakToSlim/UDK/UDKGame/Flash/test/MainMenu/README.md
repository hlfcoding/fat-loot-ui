# Application & Assets

The only assets here are ones referenced by their asset class in the source. See
265f448 for details on how the importing is offloaded to the main FLA, instead
of the previous use of `Embed`.

`MainMenuView` is the main application class linked to the main FLA. It's
responsible for loading, navigating to, and routing between each screen, and
does so primarily in its `handleNavigationRequest` method and by subclassing
`NavigableView`. Via its wrapping of the `sendCommand` utility, it sends the
respective command to the parent game process upon handling each navigation
request. Its four screens are `RootMenuView`, `HostOrJoinGameView`,
`HostGameView`, and `JoinGameView`.

The application shares its data and state with the game process via four
computed properties: `games`, `characters`, `levels`, and `gameModel`. The
objects behind those properties are observable from subclassing
`EventDispatcher`, so updating them can cause observing views to update.
`gameModel` is passed down to all screens as a reference and is modified as the
current game is configured by the user.

It also provides access to global game state via its `sharedApplication` and
`sharedRepository` singleton properties. And it has flags like `DEBUG` for
customizing large aspects for different exports of the app.
