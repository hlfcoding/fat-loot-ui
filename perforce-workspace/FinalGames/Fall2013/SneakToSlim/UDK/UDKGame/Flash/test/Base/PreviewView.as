package {

    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.net.URLRequest;

    import scaleform.clik.controls.Label;
    import scaleform.clik.controls.TextArea;

    public class PreviewView extends MovieClip {

        public var nameLabel:Label;
        public var descriptionLabel:TextArea;

        public var imageLoader:Loader;
        public var imageSize:Object;
        public var imagePathHandler:Function;

        protected var _model:Object;
        protected var _style:String;
        protected var _hasImage:Boolean;
        protected var _imageURL:String;

        public function PreviewView() {
            super();
            _hasImage = false;
        }

        public function get model():Object { return _model; }
        public function set model(value:Object):void {
            _model = value;
            nameLabel.text = model.name;
            descriptionLabel.text = model.description;
            if (hasImage) {
                imageURL = imagePathHandler(model);
                /*
                imageURL = 'http://placehold.it'.concat(
                    '/'+imageSize.width+'x'+imageSize.height,
                    '/png/&text='+model.name
                );
                */
                trace(imageURL);
            }
        }

        public function get hasImage():Boolean { return _hasImage; }
        public function set hasImage(value:Boolean):void {
            _hasImage = value;
            // Lazy init.
            if (imageLoader == null) {
                imageLoader = new Loader();
                imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
                addChild(imageLoader);
            }
        }

        public function get imageURL():String { return _imageURL; }
        public function set imageURL(value:String):void {
            if (value == _imageURL) {
                return;
            }
            _imageURL = value;
            // Auto load.
            var request:URLRequest = new URLRequest(value);
            imageLoader.load(request);
        }

        public function onLoaderComplete(event:Event):void {
            if (event.target == imageLoader.contentLoaderInfo) {
                var image:DisplayObject = imageLoader.content;
                image.width = imageSize.width;
                image.height = imageSize.height;
            }
        }

    }

}
