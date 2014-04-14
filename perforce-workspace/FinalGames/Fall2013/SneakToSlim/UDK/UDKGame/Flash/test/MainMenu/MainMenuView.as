package  {

    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.events.Event;

    import scaleform.clik.controls.Label;
    import scaleform.clik.events.ButtonEvent;

    public class MainMenuView extends NavigableView {

        public static const DEBUG:Boolean = false; // Disable in general for production builds.
        public static const USE_FIXTURES:Boolean = true;
        public static const SEND_COMMANDS:Boolean = false; // Disable for preview builds.
        public static const VERSION:String = '0.20.0';

        public var cursor:Cursor;
        public var rootMenuView:RootMenuView;
        public var hostOrJoinGameView:HostOrJoinGameView; // Also known as Lobby.
        public var hostGameView:HostGameView;
        public var joinGameView:JoinGameView;
        public var versionLabel:Label;

        protected var _gameModel:GameModel; // TODO: Sync all changes to shared game model.

        public function MainMenuView() {
            super();
            shouldDebug = MainMenuView.DEBUG;
            versionLabel.text = MainMenuView.VERSION;
            versionLabel.visible = shouldDebug;
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
                        MainMenuView.sendCommand('lobbyScreen');
                        break;
                    case rootMenuView.tutorialButton:   MainMenuView.sendCommand('playTutorialInUdk'); break;
                    case rootMenuView.creditButton:     MainMenuView.sendCommand('showCreditInUdk'); break;
                    case rootMenuView.quitButton:       MainMenuView.sendCommand('quitGameInUdk'); break;
                    // From host-or-join view.
                    case hostOrJoinGameView.joinButton:
                        toViewName = 'joinGameView';
                        var selectedModel:Object = hostOrJoinGameView.gameTableView.selectedModel;
                        gameModel.level = GameModel.getLevelById(selectedModel.level);
                        gameModel.location = selectedModel.location;
                        MainMenuView.sendCommand('joinGameScreen');
                        break;
                    case hostOrJoinGameView.hostButton:
                        toViewName = 'hostGameView';
                        MainMenuView.sendCommand('hostGameScreen');
                        break;
                    // From host view.
                    case hostGameView.hostButton:
                        toViewName = 'joinGameView';
                        gameModel.level = hostGameView.levelSelectView.selectedModel;
                        MainMenuView.sendCommand('hostGameInUdk', gameModel.location);
                        MainMenuView.sendCommand('joinGameScreen_Host');
                        break;
                    // From join view.
                    case joinGameView.joinButton:
                        gameModel.level = joinGameView.levelPreview.model;
                        commandName = 'joinGameInUdk'.concat(
                            (previousView is HostGameView) ? '_Host' : '_NonHost'
                        );
                        MainMenuView.sendCommand(commandName, gameModel.location);
                        break;
                    default: break;
                }
            // Handle restores.
            } else if (sender is String) {
                isRestoreRequest = true;
                toViewName = sender as String;
            }
            if (toViewName == null) {
                if (shouldDebug) {
                    throw new Error('No destination view name.');
                }
                return;
            }
            var toViewClassName:String = toViewName.substr(0, 1).toUpperCase().concat(toViewName.substr(1));
            // Load and store view.
            var toView:MovieClip = load(toViewClassName, toViewName);
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
                this.rootView = toView;
            } else {
                navigate(toView);
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
                    MainMenuView.sendCommand(commandName);
                }
            }
            return didNavigate;
        }

        // Helpers.

        public static function sendCommand(name:String, value:String=''):void {
            if (!MainMenuView.SEND_COMMANDS) { return; }
            Utility.sendCommand(name, value);
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
