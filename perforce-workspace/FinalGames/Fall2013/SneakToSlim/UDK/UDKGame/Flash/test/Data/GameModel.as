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
                description: "A ferocious and silent hunter, the Tiger is known for its speed and precision when taking down its prey. This Tiger is no different, even if it hunts treasure instead of animals. Or has a certain predilection for carrots.",
                skills: [
                    {
                        id: 'EarthDive',
                        name: 'Dash',
                        description: "In danger, Tiger’s true nature shows as it bunny hops away to safety."
                    },
                    {
                        id: 'TigerRoar',
                        name: 'Roar',
                        description: "Signalling impending doom, the Tiger’s Roar leaves enemies shaken!"
                    }
                ]
            },
            {
                id: 'GinsengBaby',
                name: 'Ginseng Baby',
                description: "The Ginseng Baby’s a nature spirit, tasked with protecting the surrounding forests from the expansion of the Imperial City. To that end, he has infiltrated the Empress’s city for his sacred mission. Unfortunately, his attentions often stray with a pretty piece… of treasure in the room.",
                skills: [
                    {
                        id: 'Burrow',
                        name: 'Burrow',
                        description: "Ginseng Baby returns to the earth, hidden from guards and players..."
                    },
                    {
                        id: 'Burst',
                        name: 'Burst',
                        description: "With a crash, Ginseng Baby explodes from the earth, causing localized earthquakes!"
                    }
                ]
            },
            {
                id: 'Shorty',
                name: 'Shorty',
                description: "Size isn’t everything. Fed up with the long hours and always getting the short end of the stick, Shorty looked down his nose at the Ministry of Auspicious Celestial Enforcement (also known as M.A.C.E.) WIthout any means to keep his head above water, Shorty’s turned to petty theft.",
                skills: [
                    {
                        id: 'Charge',
                        name: 'Charge',
                        description: "While he might need to build up speed, Shorty actually won the Ministry’s Contest of Heavenly Quickness."
                    },
                    {
                        id: 'OverThere',
                        name: 'Firework',
                        description: "Confiscated from neighborhood troublemakers, Shorty uses these as a distraction."
                    }
                ]
            },
            {
                id: 'FatLady',
                name: 'Lady Qian',
                description: "Who is Lady Qian? Some say a noble woman taken to a life of crime out of sheer boredom. Some say she raised herself on the streets, doing what she needed to survive. Some say she’s just a fat woman with a lot of makeup who has a streak of kleptomania. Maybe it’s paradoxically all three.",
                skills: [
                    {
                        id: 'Sprint',
                        name: 'Sprint',
                        description: "Hitching up her skirts, Lady Qian makes a break for it!"
                    },
                    {
                        id: 'BellyBump',
                        name: 'Belly Bump',
                        description: "Lady Qian inhales, inflating her body for an unstoppable leap attack!"
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
                name: 'The Duchess’ Arboretum',
                description: "How many trees does it take for a garden to become an arboretum? Exactly fifty-six, plus eight fancy statues, apparently. The duchess placed her treasure out here as an accent piece, hoping to balance the Fengshui. She also hoped that an abundance of guards would keep thieves at bay. She was wrong. Or was she?"
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
                name: 'The Empress’ Basement',
                description: "A vault-like crypt. Why does the Empress’s boiler vent underground? Rumor has it the Empress hid one of her most precious treasures down here, hoping that it would be forgotten... in the mist..."
            }
        ];

    }

}
