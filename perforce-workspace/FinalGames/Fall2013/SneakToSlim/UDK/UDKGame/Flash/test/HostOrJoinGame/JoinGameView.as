package  {

    import flash.display.MovieClip;
    import flash.events.Event;

    import scaleform.clik.controls.Button;
    import scaleform.clik.controls.TextInput;

    public class JoinGameView extends MovieClip implements IPresentableView {

        public var backButton:Button;
        public var characterSelectView:MovieClip;
        public var joinButton:Button;
        public var levelPreview:LevelPreviewViewCompact;

        public var testGameLocationInput:TextInput;

        protected var inputDebouncer:InputDebouncer;

        public var gameModel:GameModel;

        public function JoinGameView() {
            super();
            inputDebouncer = new InputDebouncer(onGameLocationChange);
            testGameLocationInput.addEventListener(Event.CHANGE, inputDebouncer.debouncedFunction);
        }

        public function get navigationBackButton():Button {
            return backButton;
        }
        public function get navigationButtons():Vector.<Button> {
            return new <Button>[joinButton];
        }

        public function onGameLocationChange(event:Event):void {
            // This is a bit of a hack.
            // Also, the view shouldn't be sending such a command.
            gameModel.location = testGameLocationInput.text;
            MainMenuView.sendCommand('setGameLocationIPInUdk', gameModel.location);
        }

        public function viewWillAppear():void {}
        public function viewDidAppear():void {}
        public function viewWillDisappear():void {}
        public function viewDidDisappear():void {}

    }

}
