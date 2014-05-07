package {

    import scaleform.clik.controls.ScrollingList;

    import scaleform.clik.constants.InvalidationType;
    import scaleform.clik.interfaces.IListItemRenderer;


    public class ExtendedScrollingList extends ScrollingList {

        public var extraPropertyNames:Vector.<String>;

        public function ExtendedScrollingList() {
            super();
        }

        public function hasOverflow():Boolean {
            return (_rowHeight * _rowCount) > height;
        }

        override protected function configUI():void {
            super.configUI();
            if (scrollBar != null) {
                scrollBar.upArrow.enabled = 
                scrollBar.downArrow.enabled = 
                scrollBar.upArrow.visible = 
                scrollBar.downArrow.visible =
                scrollBar.track.visible = false;
            }
        }

        override protected function draw():void {
            super.draw();
            /*
            if (isInvalid(InvalidationType.DATA)) {
                scrollBar.visible = hasOverflow();
            }
            */
        }

        override protected function setupRenderer(renderer:IListItemRenderer):void {
            super.setupRenderer(renderer);
            if (renderer is TableItemRenderer &&
                extraPropertyNames != null) {
                var rowRenderer:TableItemRenderer = renderer as TableItemRenderer;
                rowRenderer.extraPropertyNames = extraPropertyNames;
            }
        }

    }

}
