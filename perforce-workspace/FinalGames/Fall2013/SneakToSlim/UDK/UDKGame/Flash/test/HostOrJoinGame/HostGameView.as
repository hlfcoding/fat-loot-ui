package  {

    import flash.display.MovieClip;
    import flash.events.Event;

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

        // TODO: Click outside to blur.

        protected var inputDebouncer:InputDebouncer;

        public var gameModel:GameModel;

        public function HostGameView() {
            super();
            inputDebouncer = new InputDebouncer(onGameSettingChange);
            // Restyle.
            gameNameInput.defaultTextFormat.color =
            playerLimitInput.defaultTextFormat.color =
            scoreLimitInput.defaultTextFormat.color =
            timeLimitInput.defaultTextFormat.color = 0x0F3D0D;
        }

        public function init():void {
            levelSelectView.init();
        }

        public function addEventListeners():void {
            if (MainMenuView.USE_DEBOUNCE) {
                inputDebouncer.addEventListeners();
            }
            var changeHandler:Function = MainMenuView.USE_DEBOUNCE ?
                inputDebouncer.debouncedFunction : onGameSettingChange;
            gameNameInput.addEventListener(Event.CHANGE, changeHandler);
            playerLimitInput.addEventListener(Event.CHANGE, changeHandler);
            scoreLimitInput.addEventListener(Event.CHANGE, changeHandler);
            timeLimitInput.addEventListener(Event.CHANGE, changeHandler);
            levelSelectView.addEventListeners();
            levelSelectView.addEventListener(LevelSelectView.SELECT, onLevelSelect);
        }
        public function removeEventListeners():void {
            if (MainMenuView.USE_DEBOUNCE) {
                inputDebouncer.removeEventListeners();
            }
            var changeHandler:Function = MainMenuView.USE_DEBOUNCE ?
                inputDebouncer.debouncedFunction : onGameSettingChange;
            gameNameInput.removeEventListener(Event.CHANGE, changeHandler);
            playerLimitInput.removeEventListener(Event.CHANGE, changeHandler);
            scoreLimitInput.removeEventListener(Event.CHANGE, changeHandler);
            timeLimitInput.removeEventListener(Event.CHANGE, changeHandler);
            levelSelectView.removeEventListeners();
            levelSelectView.removeEventListener(LevelSelectView.SELECT, onLevelSelect);
        }

        public function get navigationBackButton():Button {
            return backButton;
        }
        public function get navigationButtons():Vector.<Button> {
            return new <Button>[hostButton];
        }

        public function onGameSettingChange(event:Event):void {
            var currentInput:UIComponent = MainMenuView.USE_DEBOUNCE ?
                inputDebouncer.currentInput : event.target as UIComponent;
            if (currentInput == null) { return; }
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
                MainMenuView.sendCommand(systemName, gameModel[settingName]);
            } else {
                if (textInput != null) {
                    textInput.text = '';
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
            if (MainMenuView.USE_REGEXP_TEST) {
                for each (var validator:RegExp in validators) {
                    if (!validator.test(value)) {
                        return false;
                    }
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
