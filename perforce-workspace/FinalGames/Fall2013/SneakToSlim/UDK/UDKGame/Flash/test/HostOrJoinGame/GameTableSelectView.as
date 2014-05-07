package  {

    import flash.events.Event;

    public class GameTableSelectView extends TableSelectView {

        public var gameModel:GameModel;

        public function GameTableSelectView() {
            super();
            // Configure.
            hasDividers = false;
            selectMenu.extraPropertyNames = new <String>['space', 'location'];
            // - First label.
            selectMenu.labelFunction = function(item:Object):String {
                var model:Object = item;
                return model.level;
            };
        }

        override public function init():void {
            columnNames = ['Map Name', 'Space', 'Location (IP)'];
            refreshData(this);
            super.init();
        }

        override public function addEventListeners():void {
            super.addEventListeners();
            MainMenuView.sharedRepository.addEventListener(MainRepository.GAMES_UPDATE, refreshData);
        }
        override public function removeEventListeners():void {
            super.removeEventListeners();
            MainMenuView.sharedRepository.removeEventListener(MainRepository.GAMES_UPDATE, refreshData);
        }

        override protected function get columnPropertyNames():Array {
            return ['level', 'space', 'location'];
        }

        override protected function transformItem(item:Object, index:int, source:Array):Object {
            item = super.transformItem(item, index, source);
            item.space = item._playerCount.toString().concat(' / ', GameModel.MAX_PLAYERS, ' players');
            return item;
        }

        override public function set selectedModel(value:Object):void {
            super.selectedModel = value;
            if (value != null) {
                MainMenuView.sendCommand('selectGameInUdk', value.location);
            }
        }

        protected function refreshData(sender:Object):void {
            source = MainMenuView.sharedApplication.games;
        }

    }

}
