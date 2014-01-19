package  {

    import flash.system.fscommand;

    import scaleform.clik.events.ListEvent;

    public class CharacterSelectView extends SelectView {

        public function CharacterSelectView() {
            super()
            // constructor code
            setSource([
                'Rabbit',
                'Ginseng Baby',
                'Shorty',
                'Lady Qian'
            ]);
        }

        override public function set selectedModel(value:Object):void {
            super.selectedModel = value;
            if (selectedModel != null) {
                trace('command', 'name '+selectedModel.name);
                fscommand('characterSelect', 'name '+selectedModel.name);
            }
        }

    }

}
