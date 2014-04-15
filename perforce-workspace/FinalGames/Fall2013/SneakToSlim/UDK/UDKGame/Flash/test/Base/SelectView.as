package {

    import flash.display.Bitmap;
    import flash.display.MovieClip;

    import scaleform.clik.controls.Button;
    import scaleform.clik.controls.ListItemRenderer;
    import scaleform.clik.controls.TileList;
    import scaleform.clik.constants.InvalidationType;
    import scaleform.clik.data.DataProvider;
    import scaleform.clik.events.ListEvent;
    import scaleform.clik.events.FocusHandlerEvent;

    public class SelectView extends MovieClip {

        public var collection:DataProvider;
        public var selectMenu:TileList; // TODO: Support focusing.
        public var selectPreview:PreviewView;

        public var hasBackgroundImage:Boolean;
        protected var backgroundImages:Object;

        public var hasPreviewImages:Boolean;
        protected var previewImages:Object;

        protected var _selectedModel:Object;

        public function SelectView() {
            super();
            hasBackgroundImage = true;
            hasPreviewImages = true;
            collection = DataProvider(selectMenu.dataProvider);
            collection.itemRendererName = 'SelectItemRenderer';
            selectMenu.rowHeight = selectMenu.height;
            selectMenu.addEventListener(ListEvent.ITEM_ROLL_OVER, handleItemFocus);
            selectMenu.addEventListener(ListEvent.ITEM_ROLL_OUT, handleItemFocus);
            selectMenu.addEventListener(ListEvent.INDEX_CHANGE, handleItemSelect);
        }

        public function init():void {
            // Init.
            selectMenu.selectedIndex = 0;
            selectedModel = getModelAtIndex(0);
        }

        protected function loadImages(source:Array, destination:Object):void {
            var classRef:Class;
            for each (var id:String in Utility.pluck(source, 'id')) {
                classRef = getAssetClass(id, destination);
                destination[id] = new classRef() as Bitmap;
            }
        }

        protected function getAssetClass(id:String, destination:Object):Class {
            // Override.
            if (destination === backgroundImages) {
                // Switch and return...
            } else if (destination === previewImages) {
                // Switch and return...
            }
            return Class;
        }

        public function get selectedModel():Object { return _selectedModel; }
        public function set selectedModel(value:Object):void {
            if (value === _selectedModel && value != null) { return; }
            _selectedModel = value;
            selectPreviewModel = selectedModel;
        }

        public function set source(source:Array):void {
            if (hasBackgroundImage) {
                if (backgroundImages == null) {
                    backgroundImages = {};
                    loadImages(source, backgroundImages);
                }
                for each (var data:Object in source) {
                    data.backgroundImage = backgroundImages[data.id];
                }
            }
            collection.setSource(source);
            selectMenu.columnWidth = selectMenu.width / collection.length;
            selectMenu.selectedIndex = 0;
            selectedModel = getModelAtIndex(0);
        }

        public function set selectPreviewModel(value:Object):void {
            // Preview image support.
            if (hasPreviewImages) {
                if (previewImages == null) {
                    previewImages = {};
                    loadImages(collection, previewImages);
                }
                value.image = previewImages[value.id];
            }
            selectPreview.model = value;
        }

        public function handleItemFocus(event:ListEvent):void {
            switch (event.type) {
                case ListEvent.ITEM_ROLL_OVER:
                    selectPreviewModel = getModelAtIndex(event.index);
                    break;
                case ListEvent.ITEM_ROLL_OUT:
                    if (selectedModel != null) {
                        selectPreviewModel = selectedModel;
                    }
                    break;
            }
        }

        public function handleItemSelect(event:ListEvent):void {
            if (event.type === ListEvent.INDEX_CHANGE) {
                selectedModel = getModelAtIndex(event.index);
            }
        }

        public function getModelAtIndex(index:uint):Object {
            return collection.requestItemAt(index);
        }

    }

}
