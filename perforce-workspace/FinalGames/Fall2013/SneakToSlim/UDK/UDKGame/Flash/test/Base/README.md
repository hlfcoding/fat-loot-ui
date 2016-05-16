# Base

## NavigableView

`NavigableView` is a base class inspired by `UINavigationViewController`, and as
such, its `navigate` method can push and pop views, and its outer interface
takes a generic `sender` as argument. It is meant to be subclassed with the
`handleNavigationRequest` method filled in; it is also meant to define its
screens (`MovieClip` instances implementing `IPresentableView`), as properties.
This allows `load`, `navigate`, and their subroutines to provide the max
benefit, like auto-binding for `navigationButtons` and `navigationBackButton`,
as well as only keeping one screen loaded. It also has conveniences like
`navigateBack` and `navigateToRoot`, and is designed to support different
transitions, though the only current one is the synchronous setting of
`visible`.
