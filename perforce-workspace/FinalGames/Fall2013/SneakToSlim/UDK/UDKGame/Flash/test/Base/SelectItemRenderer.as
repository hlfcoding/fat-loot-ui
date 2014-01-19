package  {

    import scaleform.clik.controls.ListItemRenderer;

    // TODO: Make into UIComponent?
    public class SelectItemRenderer extends ListItemRenderer {

        public function SelectItemRenderer() {
            super();
            // constructor code
        }

        override protected function updateAfterStateChange():void {
            super.updateAfterStateChange();
            if (textField != null) {
                textField.wordWrap = true;
                textField.multiline = true;
            }
        }

    }

}
