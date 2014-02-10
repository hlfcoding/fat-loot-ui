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
                var settingName:String = gameSettingName(currentInput);
                var systemName:String = gameSettingSystemName(settingName);
                var value:String;
                var textInput:TextInput;
                if (currentInput is TextInput) {
                    textInput = (currentInput as TextInput);
                    value = textInput.text;
                }
                if (isValid(currentInput, value)) {
                    if (value === '') {
                        if (textInput != null) {
                            value = textInput.defaultText;
                        }
                    }
                    gameModel[settingName] = value;
                    Utility.sendCommand(systemName, gameModel[settingName]);
                    currentInput = null;
                } else {
                    if (textInput != null) {
                        textInput.text = '';
                    }
                }
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

        protected function getValidators(input:UIComponent):Array {
            switch (input) {
                case playerLimitInput:  return [Utility.reNumeric];
                case scoreLimitInput:   return [Utility.reNumeric];
                case timeLimitInput:    return [Utility.reNumeric];
                default:                return [];
            }
        }

        protected function isValid(input:UIComponent, value:String):Boolean {
            var validators:Array = getValidators(input);
            for each (var validator:RegExp in validators) {
                if (!validator.test(value)) {
                    return false;
                }
            }
            return true;
        }

        public function viewWillAppear():void {}
        public function viewDidAppear():void {}
        public function viewWillDisappear():void {}
        public function viewDidDisappear():void {}

    }

}
