package {

    public class GameModel {

        public static const MAX_PLAYERS:Number = 4;

        public static const LEVELS:Array = [
            {
                id: 'Mansion',
                name: 'The Mansion',
                description: "This is The Mansion's description. It's going to take more than just one line."
            },
            {
                id: 'Temple',
                name: 'The Temple',
                description: "This is The Temple's description. It's going to take more than just one line."
            },
            {
                id: 'Pit',
                name: 'The Pit',
                description: "This is The Pit's description. It's going to take more than just one line."
            },
            {
                id: 'Mist',
                name: 'The Mist',
                description: "This is The Mist's description. It's going to take more than just one line."
            }
        ];

        public static const CHARACTERS:Array = [
            {
                id: 'Rabbit',
                name: 'Tiger',
                description: "This is Tiger's description. It's going to take more than just one line.",
                skills: [
                    {
                        id: 'EarthDive',
                        name: 'Earth Dive',
                        description: "This is Earth Dive's description. It's going to take more than just one line."
                    },
                    {
                        id: 'TigerRoar',
                        name: 'Tiger Roar',
                        description: "This is Tiger Roar's description. It's going to take more than just one line."
                    }
                ]
            },
            {
                id: 'GinsengBaby',
                name: 'Ginger',
                description: "This is Ginger's description. It's going to take more than just one line.",
                skills: [
                    {
                        id: 'Burrow',
                        name: 'Burrow',
                        description: "This is Burrow's description. It's going to take more than just one line."
                    },
                    {
                        id: 'Burst',
                        name: 'Burst',
                        description: "This is Burst's description. It's going to take more than just one line."
                    }
                ]
            },
            {
                id: 'Shorty',
                name: 'Shorty',
                description: "This is Shorty's description. It's going to take more than just one line.",
                skills: [
                    {
                        id: 'Charge',
                        name: 'Charge',
                        description: "This is Charge's description. It's going to take more than just one line."
                    },
                    {
                        id: 'OverThere',
                        name: 'OVER THERE!',
                        description: "This is OVER THERE!'s description. It's going to take more than just one line."
                    }
                ]
            },
            {
                id: 'FatLady',
                name: 'Lady Qianqing',
                description: "This is Lady Qianqing's description. It's going to take more than just one line.",
                skills: [
                    {
                        id: 'Sprint',
                        name: 'Sprint',
                        description: "This is Sprint's description. It's going to take more than just one line."
                    },
                    {
                        id: 'BellyBump',
                        name: 'Belly Bump',
                        description: "This is Belly Bump's description. It's going to take more than just one line."
                    }
                ]
            }
        ];

        public var level:Object;
        public var players:Array;
        public var location:String;

        public function GameModel(params:Object) {
            for (var key:String in params) {
                this[key] = params[key];
            }
        }

        public static function getLevelById(id:String):Object {
            for each (var level:Object in GameModel.LEVELS) {
                if (level.id === id) {
                    return level;
                }
            }
            return false;
        }

    }

}
