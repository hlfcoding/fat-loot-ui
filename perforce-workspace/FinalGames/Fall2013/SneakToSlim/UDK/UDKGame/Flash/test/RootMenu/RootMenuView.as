package  {

    import flash.display.MovieClip;

    import scaleform.clik.controls.Button;

    public class RootMenuView extends MovieClip {

        public var networkedGameButton:Button;
        public var tutorialButton:Button;
        public var creditButton:Button;
        public var quitButton:Button;

        public var gameModel:GameModel;

        public function RootMenuView() {
            super();
        }

        public function get navigationBackButton():Button {
            return null;
        }
        public function get navigationButtons():Vector.<Button> {
            return new <Button>[networkedGameButton, tutorialButton, creditButton, quitButton];
        }

        public function viewWillAppear():void {}
        public function viewDidAppear():void {}
        public function viewWillDisappear():void {}
        public function viewDidDisappear():void {}

    }

}
