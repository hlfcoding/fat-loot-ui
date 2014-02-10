package  {

    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;

    import scaleform.clik.controls.Button;
    import scaleform.clik.controls.Label;
    import scaleform.clik.controls.TextInput;
    import scaleform.clik.core.UIComponent;

    public class HostGameView extends MovieClip implements IPresentableView {

        public var backButton:Button;
        public var hostButton:Button;
        public var levelSelectView:MovieClip;

        public var gameNameInput:TextInput;
        public var playerLimitLabel:Label;
        public var playerLimitInput:TextInput;
        public var scoreLimitLabel:Label;
        public var scoreLimitInput:TextInput;
        public var timeLimitLabel:Label;
        public var timeLimitInput:TextInput;

        protected var gameSettingDebouncer:Timer;
        protected var currentInput:UIComponent;
        // TODO: Click outside to blur.

        public var gameModel:GameModel;

        public function HostGameView() {
            super();
            gameSettingDebouncer = new Timer(500, 1);
            gameSettingDebouncer.addEventListener(TimerEvent.TIMER_COMPLETE, onGameSettingChange);
            gameNameInput.addEventListener(Event.CHANGE, onGameSettingChange);
            playerLimitInput.addEventListener(Event.CHANGE, onGameSettingChange);
            scoreLimitInput.addEventListener(Event.CHANGE, onGameSettingChange);
            timeLimitInput.addEventListener(Event.CHANGE, onGameSettingChange);
            levelSelectView.addEventListener(LevelSelectView.SELECT, onLevelSelect);
        }

        public function get navigationBackButton():Button {
            return backButton;
        }
        public function get navigationButtons():Vector.<Button> {
            return new <Button>[hostButton];
        }

        public function onGameSettingChange(event:Event):void {
            // On first change event, update.
            if (event.type !== TimerEvent.TIMER_COMPLETE && !gameSettingDebouncer.running) {
                gameSettingDebouncer.start();
                currentInput = event.target as UIComponent;
            // On subsequent change events, debounce.
            } else if (gameSettingDebouncer.running) {
                return;
            // On debouncer completion, submit changes and reset.
            } else if (event.type === TimerEvent.TIMER_COMPLETE && currentInput != null) {
                var settingName = gameSettingName(currentInput);
                var systemName = gameSettingSystemName(settingName);
                if (currentInput is TextInput) {
                    var textInput:TextInput = currentInput as TextInput;
                    gameModel[settingName] = textInput.text;
                }
                Utility.sendCommand(systemName, gameModel[settingName]);
                currentInput = null;
            }
        }

        public function onLevelSelect(event:Event):void {
            gameNameInput.defaultText = levelSelectView.selectedModel.name;
        }

        protected function gameSettingName(input:UIComponent):String {
            switch (input) {
                case gameNameInput:     return 'name';
                case playerLimitInput:  return 'playerLimit';
                case scoreLimitInput:   return 'scoreLimit';
                case timeLimitInput:    return 'timeLimit';
                default: return '';
            }
        }

        protected function gameSettingSystemName(name:String):String {
            if (!name.length) {
                return '';
            }
            return 'setGame'.concat(
                name.charAt(0).toUpperCase(),
                name.substr(1),
                'InUdk'
            );
        }

        public function viewWillAppear():void {}
        public function viewDidAppear():void {}
        public function viewWillDisappear():void {}
        public function viewDidDisappear():void {}

    }

}
