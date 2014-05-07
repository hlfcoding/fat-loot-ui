package {

    import flash.display.MovieClip;
    import flash.events.Event;

    import scaleform.clik.controls.Button;
    import scaleform.clik.controls.ButtonBar;
    import scaleform.clik.controls.ListItemRenderer;
    import scaleform.clik.controls.ScrollBar;
    import scaleform.clik.data.DataProvider;
    import scaleform.clik.events.IndexEvent;
    import scaleform.clik.events.ListEvent;
    import scaleform.clik.events.FocusHandlerEvent;

    public class TableSelectView extends MovieClip {

        public var collection:DataProvider;
        public var selectMenu:ExtendedScrollingList; // TODO: Support focusing.
        public var selectPreview:PreviewView;
        public var selectScrollBar:ScrollBar;
        public var selectTopBar:ButtonBar;

        protected var _selectedModel:Object;

        public function TableSelectView() {
            super();
            collection = DataProvider(selectMenu.dataProvider);
            collection.itemRendererName = 'TableItemRenderer';
        }

        public function init():void {
            selectMenu.selectedIndex = 0;
            selectedModel = getModelAtIndex(0);
            if (selectPreview != null) {
                selectPreview.model = selectedModel;
            }
            if (selectTopBar != null) {
                var contentWidth:Number = 400;
                var baseHeight:Number = 30;
                selectTopBar.setActualScale(1, 1);
                selectTopBar.setActualSize(contentWidth, baseHeight);
                //selectTopBar.buttonWidth = contentWidth / columnNames.length;
            }
        }

        public function addEventListeners():void {
            if (selectPreview != null) {
                selectMenu.addEventListener(ListEvent.ITEM_ROLL_OVER, handleItemFocus);
                selectMenu.addEventListener(ListEvent.ITEM_ROLL_OUT, handleItemFocus);
            }
            selectMenu.addEventListener(ListEvent.INDEX_CHANGE, handleItemSelect);
            selectTopBar.addEventListener(IndexEvent.INDEX_CHANGE, handleSort);
        }
        public function removeEventListeners():void {
            if (selectPreview != null) {
                selectMenu.removeEventListener(ListEvent.ITEM_ROLL_OVER, handleItemFocus);
                selectMenu.removeEventListener(ListEvent.ITEM_ROLL_OUT, handleItemFocus);
            }
            selectMenu.removeEventListener(ListEvent.INDEX_CHANGE, handleItemSelect);
            selectTopBar.removeEventListener(IndexEvent.INDEX_CHANGE, handleSort);
        }

        public function get selectedModel():Object { return _selectedModel; }
        public function set selectedModel(value:Object):void {
            if (value === _selectedModel && value != null) { return; }
            _selectedModel = value;
            if (selectPreview != null) {
                selectPreview.model = value;
            }
        }

        public function get columnNames():Array {
            return selectTopBar.dataProvider as Array;
        }
        public function set columnNames(names:Array):void {
            (selectTopBar.dataProvider as DataProvider).setSource(names);
        }

        protected function get columnPropertyNames():Array { // Note: Implement.
            return [];
        }

        public function set source(source:Array):void {
            source.forEach(formatItem);
            collection.cleanUp();
            collection.setSource(source);
            selectMenu.selectedIndex = 0;
            selectedModel = getModelAtIndex(0);
            selectMenu.invalidateRenderers();
        }

        public function formatItem(item:Object, index:int, source:Array):Object {
            return item;
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

        public function handleSort(event:IndexEvent):void {
            if (!columnPropertyNames.length) {
                return;
            }
            var propertyName:String = columnPropertyNames[event.index];
            (collection as Array).sortOn(propertyName);
            selectMenu.invalidateData();
        }

        public function getModelAtIndex(index:uint):Object {
            return collection.requestItemAt(index);
        }

    }

}
