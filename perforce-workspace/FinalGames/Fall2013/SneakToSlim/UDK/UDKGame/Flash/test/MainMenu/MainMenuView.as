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
        public var hostOrJoinGameView:HostOrJoinGameView; // Also known as Lobby.
        public var hostGameView:HostGameView;
        public var joinGameView:JoinGameView;

        protected var _gameModel:GameModel; // TODO: Sync all changes to shared game model.

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
            var commandName:String;
            var toViewName:String;
            var isRestoreRequest:Boolean = false;
            // Handle natural navigation:
            if (sender is Event) {
                switch (sender.target) {
                    // From root menu.
                    case rootMenuView.networkedGameButton:
                        toViewName = 'hostOrJoinGameView';
                        Utility.sendCommand('lobbyScreen');
                        break;
                    case rootMenuView.tutorialButton:   Utility.sendCommand('playTutorialInUdk'); break;
                    case rootMenuView.creditButton:     Utility.sendCommand('showCreditInUdk'); break;
                    case rootMenuView.quitButton:       Utility.sendCommand('quitGameInUdk'); break;
                    // From host-or-join view.
                    case hostOrJoinGameView.joinButton:
                        toViewName = 'joinGameView';
                        var selectedModel:Object = hostOrJoinGameView.gameTableView.selectedModel;
                        gameModel.level = GameModel.getLevelById(selectedModel.level);
                        gameModel.location = selectedModel.location;
                        Utility.sendCommand('joinGameScreen');
                        break;
                    case hostOrJoinGameView.hostButton:
                        toViewName = 'hostGameView';
                        Utility.sendCommand('hostGameScreen');
                        break;
                    // From host view.
                    case hostGameView.hostButton:
                        toViewName = 'joinGameView';
                        gameModel.level = hostGameView.levelSelectView.selectedModel;
                        Utility.sendCommand('hostGameInUdk', gameModel.location);
                        Utility.sendCommand('joinGameScreen_Host');
                        break;
                    // From join view.
                    case joinGameView.joinButton:
                        gameModel.level = joinGameView.levelPreview.model;
                        commandName = 'joinGameInUdk'.concat(
                            (previousView is HostGameView) ? '_Host' : '_NonHost'
                        );
                        Utility.sendCommand(commandName, gameModel.location);
                        break;
                    default: break;
                }
            // Handle restores.
            } else if (sender is String) {
                isRestoreRequest = true;
                toViewName = sender as String;
            }
            if (toViewName == null) {
                return;
            }
            var toViewClassName:String = toViewName.substr(0, 1).toUpperCase().concat(toViewName.substr(1));
            // Load and store view.
            load(toViewClassName, toViewName);
            // Setup view as needed.
            switch (toViewName) {
                case 'joinGameView':
                    joinGameView.levelPreview.model = gameModel.level;
                    break;
                case 'hostGameView':
                    hostGameView.gameModel = gameModel;
                    break;
                default: break;
            }
            // Navigate.
            if (isRestoreRequest) {
                this.rootView = this[toViewName];
            } else {
                navigate(this[toViewName]);
            }
        }

        override public function load(className:String, propertyName:String=null):MovieClip {
            var view:MovieClip = super.load(className, propertyName);
            view['gameModel'] = gameModel;
            return view;
        }

        override public function navigateBack(sender:Object=null):Boolean {
            var didNavigate:Boolean = super.navigateBack(sender);
            if (didNavigate && sender is Event) {
                var commandName:String = 'backTo';
                if (hostOrJoinGameView != null && sender.target == hostOrJoinGameView.backButton) {
                    commandName += 'RootMenu';
                } else if (hostGameView != null && sender.target == hostGameView.backButton) {
                    commandName += 'Lobby_Host';
                } else if (joinGameView != null && sender.target == joinGameView.backButton) {
                    commandName += (currentView is HostGameView) ?
                        'HostGame_Host' : 'Lobby_NonHost';
                }
                if (commandName != 'backTo') {
                    Utility.sendCommand(commandName);
                }
            }
            return didNavigate;
        }

        // UDK endpoints.

        public function set games(games:Array):void {
            GameModel.games = games;
        }

        public function set characters(characters:Array):void {
            GameModel.characters = characters;
        }

        public function set levels(levels:Array):void {
            GameModel.levels = levels;
        }

        public function get gameModel():GameModel {
            return _gameModel;
        }
        public function set gameModel(value:GameModel):void {
            _gameModel = value as GameModel;
        }

        public function restore(toViewName:String, toGameModel:Object):void {
            gameModel = toGameModel as GameModel;
            handleNavigationRequest(toViewName);
        }

    }

}
