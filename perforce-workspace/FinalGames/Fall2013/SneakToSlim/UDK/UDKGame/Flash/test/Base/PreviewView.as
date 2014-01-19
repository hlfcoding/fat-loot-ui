package {

    import flash.display.MovieClip;

    import scaleform.clik.controls.Label;

    public class PreviewView extends MovieClip {

        public var nameLabel:Label;

        protected var _model:Object;

        public function PreviewView() {
            // constructor code
        }

        public function get model():Object { return _model; }
        public function set model(value:Object):void {
            _model = value;
            nameLabel.text = model.name;
        }
    }

}
