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

## SelectView

`SelectView` is a base class for a compound view consisting of a CLIK `TileList`
and an optional `PreviewView`, backed by a CLIK `DataProvider`. This is a common
view in the application, where the selected item should be previewed in a larger
view. Its `selectedModel`, `selectedPreviewModel`, and `source` are all
accessible and kept up-to-date to some degree, where the model is a typical
data-layer object. It is meant to be subclassed with the `getAssetClass` method
filled in.

For items, it uses a customized `SelectItemRenderer` that extends the CLIK
`ListItemRenderer` with common model-specific behaviors, like displaying a
background image under its text label. Similarly, its `PreviewView` is just a
basic view with a couple labels over an image.
