# Data Layer

The data layer is basic. `MainRepository` stores its collections as plain JSON-
like arrays of objects and only has one change event: `GAMES_UPDATE`. Its
`*_FIXTURE` constants are a good reference on the data schema. `GameModel` is a
plain container for a superset of the game collection object's data that comes
from the parent game process.
