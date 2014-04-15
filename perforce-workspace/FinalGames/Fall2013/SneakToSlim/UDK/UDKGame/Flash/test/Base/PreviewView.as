package {

    import flash.display.Bitmap;
    import flash.display.MovieClip;

    import scaleform.clik.controls.Label;
    import scaleform.clik.controls.TextArea;

    public class PreviewView extends MovieClip {

        public var nameLabel:Label;
        public var descriptionLabel:TextArea;
        public var image:Bitmap;

        // FIXME: Perhaps making this a UIComponent would help.
        public var imageOffset:Object;
        public var imageSize:Object;

        protected var _model:Object;
        protected var _style:String;

        public function PreviewView() {
            super();
            nameLabel.visible = false;
        }

        public function get model():Object { return _model; }
        public function set model(value:Object):void {
            _model = value;
            nameLabel.text = model.name;
            descriptionLabel.text = model.description;
            if (model.image != null) {
                var shouldDrawImage:Boolean = image == null || contains(image);
                if (shouldDrawImage) {
                    if (image != null) {
                        removeChild(image);
                    }
                    image = model.image as Bitmap;
                    drawImage();
                }
            }
        }

        protected function drawImage():void {
            addChildAt(image, 0);
            if (imageOffset != null) {
                image.x = imageOffset.x;
                image.y = imageOffset.y;
            }
            if (imageSize != null) {
                image.width = imageSize.width;
                image.height = imageSize.height;
            }
        }

    }

}
