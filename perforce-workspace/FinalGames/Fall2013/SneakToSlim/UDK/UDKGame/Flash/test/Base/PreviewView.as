package {

    import flash.display.MovieClip;

    import scaleform.clik.controls.Label;
    import scaleform.clik.controls.TextArea;

    public class PreviewView extends MovieClip {

        public var nameLabel:Label;
        public var descriptionLabel:TextArea;

        protected var _model:Object;
        protected var _style:String;

        public function PreviewView() {
        }

        public function get model():Object { return _model; }
        public function set model(value:Object):void {
            _model = value;
            nameLabel.text = model.name;
            descriptionLabel.text = model.description;
        }

    }

}
