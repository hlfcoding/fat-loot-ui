package  {

    import flash.display.Bitmap;
    import flash.display.Shape;
    import flash.events.Event;
    import flash.net.URLRequest;

    import scaleform.clik.constants.ConstrainMode;
    import scaleform.clik.constants.InvalidationType;
    import scaleform.clik.controls.ListItemRenderer;
    import scaleform.clik.utils.Constraints;

    public class SelectItemRenderer extends ListItemRenderer {

        protected var backgroundImage:Bitmap;
        protected var bgImageConstraints:Constraints;

        public function SelectItemRenderer() {
            super();
        }

        override protected function draw():void {
            super.draw();
            // Extend conventional behavior.
            if (isInvalid(InvalidationType.SIZE) ) {
                if (bgImageConstraints != null && !constraintsDisabled && backgroundImage != null) {
                    bgImageConstraints.update(_width, _height);
                }
            }
        }

        override protected function updateAfterStateChange():void {
            super.updateAfterStateChange();
            if (!initialized) { return; }
            if (textField != null) {
                textField.wordWrap = true;
                textField.multiline = true;
            }
        }

        override public function setData(data:Object):void {
            if (data == null) {
                return;
            }
            super.setData(data);
            if (data.locked === true) {
                this.enabled = false;
            }
            // Background image support.
            if (data.backgroundImage != null && data.locked !== true) {
                var shouldDrawImage:Boolean = backgroundImage == null || contains(backgroundImage);
                if (shouldDrawImage) {
                    if (backgroundImage != null) {
                        removeChild(backgroundImage);
                    }
                    backgroundImage = data.backgroundImage as Bitmap;
                    drawBackgroundImage();
                }
            }
        }

        protected function drawBackgroundImage():void {
            addChildAt(backgroundImage, 1);
            if (!constraintsDisabled && bgImageConstraints == null) {
                // Lazy init.
                backgroundImage.width = _originalWidth;
                backgroundImage.height = _originalHeight;
                bgImageConstraints = new Constraints(this, ConstrainMode.COUNTER_SCALE);
                bgImageConstraints.addElement('backgroundImage', backgroundImage, Constraints.ALL);
                //trace('[CONSTRAINTS]', bgImageConstraints);
            }
            invalidateSize();
        }

    }

}
