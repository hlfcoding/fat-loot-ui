package {

    import flash.display.MovieClip;
    import flash.events.Event;

    import scaleform.clik.controls.Button;
    import scaleform.clik.controls.ListItemRenderer;
    import scaleform.clik.controls.TileList;
    import scaleform.clik.data.DataProvider;
    import scaleform.clik.events.ListEvent;
    import scaleform.clik.events.FocusHandlerEvent;

    public class SelectView extends MovieClip {

        public var collection:DataProvider;
        public var selectMenu:TileList;
        public var selectPreview:PreviewView;

        protected var _selectedModel:Object;

        public function SelectView() {
            // constructor code
            collection = DataProvider(selectMenu.dataProvider);
            selectMenu.rowHeight = selectMenu.height;
            selectMenu.addEventListener(ListEvent.ITEM_ROLL_OVER, handleItemFocus, false, 0, true);
            selectMenu.addEventListener(ListEvent.ITEM_ROLL_OUT, handleItemFocus, false, 0, true);
            selectMenu.addEventListener(ListEvent.INDEX_CHANGE, handleItemSelect, false, 0, true);
            // Init.
            selectMenu.selectedIndex = 0;
            selectedModel = selectPreview.model = getModelAtIndex(0);
        }

        public function get selectedModel():Object { return _selectedModel; }
        public function set selectedModel(value:Object):void {
            _selectedModel = value;
        }

        public function setSource(source:Array):void {
            collection.setSource(source);
            selectMenu.columnWidth = selectMenu.width / collection.length;
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
            selectedModel = selectPreview.model;
        }

        public function getModelAtIndex(index:uint):Object {
            return {
                name: collection.requestItemAt(index)
            };
        }

    }

}
