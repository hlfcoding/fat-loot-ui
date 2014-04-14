package {

    import flash.events.Event;

    public class LevelSelectView extends SelectView {

        public var gameModel:GameModel;

        public static const SELECT:String = 'levelSelect';

        public function LevelSelectView() {
            super()
            // Configure.
            hasBackgroundImage = true;
            backgroundImagePathHandler = function(data:Object):String {
                return 'Assets'.concat('/level-', data.id.toLowerCase(), '.png');
            };
            selectMenu.labelFunction = function(item:Object):String {
                var model:Object = item;
                return model.name;
            };
            selectPreview.nameLabel.visible = false;
            // Commit.
            source = GameModel.levels;
            init();
        }

        override public function set selectedModel(value:Object):void {
            super.selectedModel = value;
            if (selectedModel != null) {
                MainMenuView.sendCommand('selectGameMapInUdk', selectedModel.id);
            }
            dispatchEvent(new Event(LevelSelectView.SELECT));
        }

    }

}
