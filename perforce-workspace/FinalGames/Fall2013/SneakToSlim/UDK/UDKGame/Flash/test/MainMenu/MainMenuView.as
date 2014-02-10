package  {

    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.events.Event;

    import scaleform.clik.events.ButtonEvent;

    public class MainMenuView extends NavigableView {

        public static const DEBUG = true;
        public static const USE_FIXTURES = true;

        public var cursor:Cursor;
        public var rootMenuView:RootMenuView;
        public var hostOrJoinGameView:HostOrJoinGameView;
        public var hostGameView:HostGameView;
        public var joinGameView:JoinGameView;

        protected var gameModel:GameModel; // TODO: Sync all changes to shared game model.

        public function MainMenuView() {
            super();
            load('RootMenuView', 'rootMenuView');
            rootView = rootMenuView;
            gameModel = new GameModel({
                level: null,
                location: 'TODO: Get IP',
                players: []
            });
        }

        override public function addChild(child:DisplayObject):DisplayObject {
            super.addChild(child);
            setChildIndex(cursor, numChildren - 1);
            return child;
        }

        override public function handleNavigationRequest(sender:Object):void {
            if (!(sender is Event)) {
                return;
            }
            switch (sender.target) {
                case rootMenuView.networkedGameButton:

                    load('HostOrJoinGameView', 'hostOrJoinGameView');
                    navigate(hostOrJoinGameView);

                break; case rootMenuView.tutorialButton:

                    Utility.sendCommand('playTutorialInUdk');

                break; case rootMenuView.creditButton:

                    Utility.sendCommand('showCreditInUdk');

                break; case rootMenuView.quitButton:

                    Utility.sendCommand('quitGameInUdk');

                break; case hostOrJoinGameView.joinButton:

                    var selectedModel:Object = hostOrJoinGameView.gameTableView.selectedModel;
                    gameModel.level = GameModel.getLevelById(selectedModel.level);
                    gameModel.location = selectedModel.location;

                    load('JoinGameView', 'joinGameView');
                    joinGameView.levelPreview.model = gameModel.level;
                    navigate(joinGameView);

                break; case hostOrJoinGameView.hostButton:

                    load('HostGameView', 'hostGameView');
                    hostGameView.gameModel = gameModel;
                    navigate(hostGameView);

                break; case hostGameView.hostButton:

                    gameModel.level = hostGameView.levelSelectView.selectedModel;
                    Utility.sendCommand('hostGameInUdk', gameModel.location);

                    load('JoinGameView', 'joinGameView');
                    joinGameView.levelPreview.model = gameModel.level;
                    navigate(joinGameView);

                break; case joinGameView.joinButton:

                    gameModel.level = joinGameView.levelPreview.model;
                    Utility.sendCommand('joinGameInUdk', gameModel.location);

                break; default: break;
            }
        }

        override public function load(className:String, propertyName:String=null):MovieClip {
            var view:MovieClip = super.load(className, propertyName);
            view['gameModel'] = gameModel;
            return view;
        }

    }

}
