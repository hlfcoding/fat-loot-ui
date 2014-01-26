package  {

    import scaleform.clik.controls.ListItemRenderer;

    public class SelectItemRenderer extends ListItemRenderer {

        public function SelectItemRenderer() {
            super();
        }

        override protected function updateAfterStateChange():void {
            super.updateAfterStateChange();
            if (textField != null) {
                textField.wordWrap = true;
                textField.multiline = true;
            }
        }

        override public function setData(data:Object):void {
            if (data == null) {
                return;
            }
            this.data = data;
        }

    }

}
