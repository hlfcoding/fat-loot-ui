package {

    public class LevelSelectView extends SelectView {

        public var gameModel:GameModel;

        public function LevelSelectView() {
            super()
            // Configure.
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
                Utility.sendCommand('selectGameMapInUdk', selectedModel.id);
            }
        }

    }

}
