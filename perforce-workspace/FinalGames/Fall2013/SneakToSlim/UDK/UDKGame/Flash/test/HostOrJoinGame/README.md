# Lobby, Host & Join Game Screens

`HostOrJoinGameView` is the lobby screen. From there a new game can be created
by going to the `HostGameView` via the `hostButton`, an existing game can be
joined by selecting the row in `GameTableSelectView` and going to the
`JoinGameView` via the `joinButton`. The games list can also be refreshed via
the `refreshButton` and the associated `requestGamesInUdk` command.

`HostGameView` is the game creation view that includes, beyond a
`LevelSelectView`, additional inputs for configuring the game. For the CLIK
`TextInput`s with `Label`s, it also uses an `InputDebouncer` and performs
validation (per `USE_REGEXP_TEST`). The new game can be joined on the next
`JoinGameView`.

`JoinGameView` is the final, character and skill select screen. It also has a
`LevelPreviewViewCompact` that's only defined in the FLA. The app effectively
ends with its `joinButton`.

Note that routing logic is mostly not defined in these classes but in
`MainMenuView`.
