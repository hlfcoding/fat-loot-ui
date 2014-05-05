package  {


    public class GameTableSelectView extends TableSelectView {

        public var gameModel:GameModel;

        public function GameTableSelectView() {
            super();
            // Configure.
            selectMenu.extraPropertyNames = new <String>['space', 'location'];
            // - First label.
            selectMenu.labelFunction = function(item:Object):String {
                var model:Object = item;
                return model.level;
            };
            // Commit.
            columnNames = ['Map Name', 'Space', 'Location (IP)'];
            source = MainMenuView.sharedApplication.games;
            init();
        }

        override protected function get columnPropertyNames():Array {
            return ['level', 'space', 'location'];
        }

        override public function formatItem(item:Object, index:int, source:Array):Object {
            item.space = item._playerCount.toString().concat(' / ', GameModel.MAX_PLAYERS, ' players');
            return item;
        }

        override public function set selectedModel(value:Object):void {
            super.selectedModel = value;
            if (value != null) {
                MainMenuView.sendCommand('selectGameInUdk', value.location);
            }
        }

    }

}
