# Character & Skill Selects

`CharacterSelectView` is a basic `SelectView` final class, but also handles
updating state for its owned `SkillSelectView`, which should show the skills for
the _selected_ character. Skill selection currently does not get saved. The view
also supports background and preview images.

`SkillSelectView` is a basic `SelectView` final class. It is owned by a parent
`CharacterSelectView` instance. It supports preview images, but that isn't
currently being used by the app.
