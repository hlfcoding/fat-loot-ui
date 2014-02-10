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

        public var timeLimitLabel:Label;
        public var timeLimitInput:TextInput;
        public var scoreLimitLabel:Label;
        public var scoreLimitInput:TextInput;
        public var playerLimitLabel:Label;
        public var playerLimitInput:TextInput;
        // TODO: Click outside to blur.

        public var gameModel:GameModel;

        public function HostGameView() {
            super();
            timeLimitInput.addEventListener(Event.CHANGE, onGameSettingChange);
            scoreLimitInput.addEventListener(Event.CHANGE, onGameSettingChange);
            playerLimitInput.addEventListener(Event.CHANGE, onGameSettingChange);
        }

        public function get navigationBackButton():Button {
            return backButton;
        }
        public function get navigationButtons():Vector.<Button> {
            return new <Button>[hostButton];
        }

        public function onGameSettingChange(event:Event):void {
            var settingName:String = gameSettingName(event.target as UIComponent);
            var systemName:String = gameSettingSystemName(settingName);
            if (event.target is TextInput) {
                var textInput:TextInput = event.target as TextInput;
                gameModel[settingName] = textInput.text;
                Utility.sendCommand(systemName, textInput.text);
            }
        }

        protected function gameSettingName(input:UIComponent):String {
            switch (input) {
                case timeLimitInput: return 'timeLimit';
                case scoreLimitInput: return 'scoreLimit';
                case playerLimitInput: return 'playerLimit';
                default: return '';
            }
        }

        protected function gameSettingSystemName(name:String):String {
            if (!name.length) {
                return '';
            }
            return 'set'.concat(
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
