package  {

    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.Shape;
    import flash.events.Event;
    import flash.net.URLRequest;

    import scaleform.clik.constants.ConstrainMode;
    import scaleform.clik.constants.InvalidationType;
    import scaleform.clik.controls.ListItemRenderer;
    import scaleform.clik.utils.Constraints;

    public class SelectItemRenderer extends ListItemRenderer {

        protected var bgImageLoader:Loader;
        protected var bgImageConstraints:Constraints;
        protected var _hasBGImage:Boolean;
        protected var _bgImageURL:String;

        public function SelectItemRenderer() {
            super();
            _hasBGImage = false;
        }

        override protected function draw():void {
            super.draw();
            // Extend conventional behavior.
            if (isInvalid(InvalidationType.SIZE) ) {
                if (bgImageConstraints != null && !constraintsDisabled && bgImageLoader != null) {
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
            if (data.hasBackgroundImage != null) {
                hasBackgroundImage = data.hasBackgroundImage;
            }
            if (hasBackgroundImage) {
                bgImageURL = data.backgroundImagePathHandler(data);
                //bgImageURL = 'http://placehold.it/100/png/&text='+data.name;
                trace(bgImageURL);
            }
        }

        [Inspectable(defaultValue = "false")]
        public function get hasBackgroundImage():Boolean { return _hasBGImage; }
        public function set hasBackgroundImage(value:Boolean):void {
            _hasBGImage = value;
            // Lazy init.
            if (bgImageLoader == null) {
                bgImageLoader = new Loader();
                bgImageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
                addChildAt(bgImageLoader, 1);
            }
        }

        public function get bgImageURL():String { return _bgImageURL; }
        public function set bgImageURL(value:String):void {
            if (value == _bgImageURL) {
                return;
            }
            _bgImageURL = value;
            // Auto load.
            var request:URLRequest = new URLRequest(value);
            bgImageLoader.load(request);
        }

        public function onLoaderComplete(event:Event):void {
            if (event.target == bgImageLoader.contentLoaderInfo) {
                if (!constraintsDisabled && bgImageConstraints == null) {
                    // Lazy init.
                    var bgImage:DisplayObject = bgImageLoader.content;
                    bgImage.width = _originalWidth;
                    bgImage.height = _originalHeight;
                    bgImageConstraints = new Constraints(this, ConstrainMode.COUNTER_SCALE);
                    bgImageConstraints.addElement('bgImage', bgImage, Constraints.ALL);
                    //trace('[CONSTRAINTS]', bgImageConstraints);
                }
                invalidateSize();
            }
        }

    }

}
