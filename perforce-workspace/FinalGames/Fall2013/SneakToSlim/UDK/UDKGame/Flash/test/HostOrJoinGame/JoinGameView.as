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
            levelPreview.nameLabel.visible = true;
            levelPreview.imageSize = { width: 427, height: 267 };
            levelPreview.imageOffset = {
                x: (levelPreview.width - levelPreview.imageSize.width) / 2,
                y: 0
            };
            addChild(Utility.hideViewOverflow(levelPreview));
        }

        public function init():void {
            characterSelectView.init();
            // Toggle as needed.
            testGameLocationInput.visible = false;
        }

        public function addEventListeners():void {
            characterSelectView.addEventListeners();
            if (MainMenuView.USE_DEBOUNCE) {
                inputDebouncer.addEventListeners();
            }
            testGameLocationInput.addEventListener(Event.CHANGE, MainMenuView.USE_DEBOUNCE ?
                inputDebouncer.debouncedFunction : onGameLocationChange);
        }
        public function removeEventListeners():void {
            characterSelectView.removeEventListeners();
            if (MainMenuView.USE_DEBOUNCE) {
                inputDebouncer.removeEventListeners();
            }
            testGameLocationInput.removeEventListener(Event.CHANGE, MainMenuView.USE_DEBOUNCE ?
                inputDebouncer.debouncedFunction : onGameLocationChange);
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
