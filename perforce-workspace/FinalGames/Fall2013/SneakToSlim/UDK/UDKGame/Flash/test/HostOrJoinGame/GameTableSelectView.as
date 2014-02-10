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
            columnNames = [ 'Map Name', 'Space', 'Location (IP)' ];
            source = GameModel.games;
            init();
        }

        override public function formatItem(item:Object, index:int, source:Array):Object {
            item.space = item._playerCount.toString().concat(' / ', GameModel.MAX_PLAYERS, ' players');
            return item;
        }

        override public function set selectedModel(value:Object):void {
            super.selectedModel = value;
            if (value != null) {
                Utility.sendCommand('selectGameInUdk', value.location);
            }
        }

    }

}
