package {

    public class GameModel {

        public static const MAX_PLAYERS:Number = 4;

        public static var characters:Array;
        public static var games:Array;
        public static var levels:Array;

        public var level:Object;
        public var location:String;
        public var name:String;
        public var players:Array;

        public var playerLimit:String;
        public var scoreLimit:String;
        public var timeLimit:String;

        public function GameModel(params:Object) {
            // Init static vars as needed.
            if (GameModel.levels == null || GameModel.characters == null) {
                if (MainMenuView.USE_FIXTURES) {
                    GameModel.levels = GameModel.LEVELS_FIXTURE;
                    GameModel.characters = GameModel.CHARACTERS_FIXTURE;
                    GameModel.games = GameModel.GAMES_FIXTURE;
                }
            }
            // Init model.
            for (var key:String in params) {
                this[key] = params[key];
            }
        }

        public static function getLevelById(id:String):Object {
            for each (var level:Object in GameModel.levels) {
                if (level.id === id) {
                    return level;
                }
            }
            return false;
        }

        public static const CHARACTERS_FIXTURE:Array = [
            {
                id: 'Rabbit',
                name: 'Tiger',
                description: "This is Tiger's description. It's going to take more than just one line. It's going to take more than just two lines.",
                skills: [
                    {
                        id: 'EarthDive',
                        name: 'Earth Dive',
                        description: "This is Earth Dive's description. It's going to take more than just one line. It's going to take more than just two lines."
                    },
                    {
                        id: 'TigerRoar',
                        name: 'Tiger Roar',
                        description: "This is Tiger Roar's description. It's going to take more than just one line. It's going to take more than just two lines."
                    }
                ]
            },
            {
                id: 'GinsengBaby',
                name: 'Ginger',
                description: "This is Ginger's description. It's going to take more than just one line. It's going to take more than just two lines.",
                skills: [
                    {
                        id: 'Burrow',
                        name: 'Burrow',
                        description: "This is Burrow's description. It's going to take more than just one line. It's going to take more than just two lines."
                    },
                    {
                        id: 'Burst',
                        name: 'Burst',
                        description: "This is Burst's description. It's going to take more than just one line. It's going to take more than just two lines."
                    }
                ]
            },
            {
                id: 'Shorty',
                name: 'Shorty',
                description: "This is Shorty's description. It's going to take more than just one line. It's going to take more than just two lines.",
                skills: [
                    {
                        id: 'Charge',
                        name: 'Charge',
                        description: "This is Charge's description. It's going to take more than just one line. It's going to take more than just two lines."
                    },
                    {
                        id: 'OverThere',
                        name: 'OVER THERE!',
                        description: "This is OVER THERE!'s description. It's going to take more than just one line. It's going to take more than just two lines."
                    }
                ]
            },
            {
                id: 'FatLady',
                name: 'Lady Qianqing',
                description: "This is Lady Qianqing's description. It's going to take more than just one line. It's going to take more than just two lines.",
                skills: [
                    {
                        id: 'Sprint',
                        name: 'Sprint',
                        description: "This is Sprint's description. It's going to take more than just one line. It's going to take more than just two lines."
                    },
                    {
                        id: 'BellyBump',
                        name: 'Belly Bump',
                        description: "This is Belly Bump's description. It's going to take more than just one line. It's going to take more than just two lines."
                    }
                ]
            }
        ];

        public static const GAMES_FIXTURE:Array = [
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

        public static const LEVELS_FIXTURE:Array = [
            {
                id: 'Mansion',
                name: 'The Mansion',
                description: "This is The Mansion's description. It's going to take more than just one line. It's going to take more than just two lines."
            },
            {
                id: 'Temple',
                name: 'The Temple',
                description: "This is The Temple's description. It's going to take more than just one line. It's going to take more than just two lines."
            },
            {
                id: 'Pit',
                name: 'The Pit',
                description: "This is The Pit's description. It's going to take more than just one line. It's going to take more than just two lines."
            },
            {
                id: 'Mist',
                name: 'The Mist',
                description: "This is The Mist's description. It's going to take more than just one line. It's going to take more than just two lines."
            }
        ];

    }

}
