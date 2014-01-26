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
            source = [
                {
                    id: 0,
                    level: 'Temple',
                    _playerCount: 1,
                    location: '128.125.121.0'
                },
                {
                    id: 1,
                    level: 'Mansion',
                    _playerCount: 2,
                    location: '128.125.121.1'
                },
                {
                    id: 2,
                    level: 'Pit',
                    _playerCount: 3,
                    location: '128.125.121.2'
                },
                {
                    id: 3,
                    level: 'Mist',
                    _playerCount: 4,
                    location: '128.125.121.3'
                },
                {
                    id: 4,
                    level: 'Mansion',
                    _playerCount: 1,
                    location: '128.125.121.0'
                },
                {
                    id: 1,
                    level: 'Mansion',
                    _playerCount: 1,
                    location: '128.125.121.0'
                },
                {
                    id: 1,
                    level: 'Mansion',
                    _playerCount: 1,
                    location: '128.125.121.0'
                },
                {
                    id: 1,
                    level: 'Mansion',
                    _playerCount: 1,
                    location: '128.125.121.0'
                },
                {
                    id: 1,
                    level: 'Mansion',
                    _playerCount: 1,
                    location: '128.125.121.0'
                },
                {
                    id: 1,
                    level: 'Mansion',
                    _playerCount: 1,
                    location: '128.125.121.0'
                },
                {
                    id: 1,
                    level: 'Mansion',
                    _playerCount: 1,
                    location: '128.125.121.0'
                },
                {
                    id: 1,
                    level: 'Mansion',
                    _playerCount: 1,
                    location: '128.125.121.0'
                },
                {
                    id: 1,
                    level: 'Mansion',
                    _playerCount: 1,
                    location: '128.125.121.0'
                },
                {
                    id: 1,
                    level: 'Mansion',
                    _playerCount: 1,
                    location: '128.125.121.0'
                }
            ];
            init();
        }

        override public function formatItem(item:Object, index:int, source:Array):Object {
            item.space = item._playerCount.toString().concat(' / ', GameModel.MAX_PLAYERS, ' players');
            return item;
        }

        override public function set selectedModel(value:Object):void {
            super.selectedModel = value;
            if (value != null) {
                Utility.sendCommand('gameSelect', 'selectGameInUdk', value.location);
            }
        }

    }

}
