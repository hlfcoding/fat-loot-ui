package {

    import flash.events.Event;
    import flash.events.EventDispatcher;

    public class GameModel extends EventDispatcher {

        public static const MAX_PLAYERS:Number = 4;

        public var level:Object;
        public var location:String;
        public var name:String;
        public var players:Array;

        public var playerLimit:String;
        public var scoreLimit:String;
        public var timeLimit:String;

        public function GameModel(params:Object) {
            super();
            // Init model.
            for (var key:String in params) {
                this[key] = params[key];
            }
        }

    }

}
