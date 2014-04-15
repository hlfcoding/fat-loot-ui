package {

    import flash.display.MovieClip;
    import flash.events.Event;

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
        public var backgroundImagePathHandler:Function;

        protected var _selectedModel:Object;

        public function SelectView() {
            super();
            hasBackgroundImage = false;
            backgroundImagePathHandler = function(data:Object):String {
                return 'Assets'.concat('/', data.id.toLowerCase(), '.jpg');
            };
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
            selectedModel = selectPreview.model = getModelAtIndex(0);
        }

        public function get selectedModel():Object { return _selectedModel; }
        public function set selectedModel(value:Object):void {
            if (value === _selectedModel && value != null) { return; }
            _selectedModel = value;
            selectPreview.model = value;
        }

        public function set source(source:Array):void {
            if (hasBackgroundImage) {
                // Makeshift way of passing this through.
                for each (var data:Object in source) {
                    data.hasBackgroundImage = hasBackgroundImage;
                    data.backgroundImagePathHandler = backgroundImagePathHandler;
                }
            }
            collection.setSource(source);
            selectMenu.columnWidth = selectMenu.width / collection.length;
            selectMenu.selectedIndex = 0;
            selectedModel = getModelAtIndex(0);
        }

        public function handleItemFocus(event:ListEvent):void {
            switch (event.type) {
                case ListEvent.ITEM_ROLL_OVER:
                    selectPreview.model = getModelAtIndex(event.index);
                    break;
                case ListEvent.ITEM_ROLL_OUT:
                    if (selectedModel != null) {
                        selectPreview.model = selectedModel;
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
