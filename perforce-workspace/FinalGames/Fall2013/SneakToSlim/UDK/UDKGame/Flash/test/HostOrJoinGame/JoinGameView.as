package  {

    import flash.display.MovieClip;

    import scaleform.clik.controls.Button;

    public class JoinGameView extends MovieClip implements IPresentableView {

        public var backButton:Button;
        public var characterSelectView:MovieClip;
        public var joinButton:Button;
        public var levelPreview:LevelPreviewViewCompact;

        public var gameModel:GameModel;

        public function JoinGameView() {
            super();
        }

        public function get navigationBackButton():Button {
            return backButton;
        }
        public function get navigationButtons():Vector.<Button> {
            return new <Button>[joinButton];
        }

        public function viewWillAppear():void {}
        public function viewDidAppear():void {}
        public function viewWillDisappear():void {}
        public function viewDidDisappear():void {}

    }

}
