package  {

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.text.TextFieldAutoSize;

    import scaleform.clik.controls.Label;
    import scaleform.clik.events.ButtonEvent;

    public class MainMenuView extends NavigableView {

        public static const DEBUG:Boolean = true; // Disable in general for production builds.
        public static const USE_FIXTURES:Boolean = true;
        public static const SEND_COMMANDS:Boolean = true; // Disable for preview or debugger builds.
        public static const VERSION:String = '0.27.0';

        public var cursor:Cursor;
        public var rootMenuView:RootMenuView;
        public var hostOrJoinGameView:HostOrJoinGameView; // Also known as Lobby.
        public var hostGameView:HostGameView;
        public var joinGameView:JoinGameView;
        public var versionLabel:Label;

        protected static var _sharedApplication:MainMenuView;

        // Data. Doesn't include proxy accessors.
        public var repository:MainRepository;
        protected var _gameModel:GameModel; // TODO: Sync all changes to shared game model.

        public function MainMenuView() {
            if (MainMenuView._sharedApplication == null) {
                super();
                MainMenuView._sharedApplication = this;
            } else if (MainMenuView.DEBUG) {
                throw new Error('MainMenuView is a singleton.');
            }
            shouldDebug = MainMenuView.DEBUG;
            addVersionLabel();
            load('RootMenuView', 'rootMenuView');
            rootView = rootMenuView;
            repository = new MainRepository();
            if (MainMenuView.USE_FIXTURES) {
                repository.initFromFixtures();
            }
            gameModel = new GameModel({
                level: null,
                location: 'TODO: Get IP',
                players: []
            });
        }

        public static function get sharedApplication():MainMenuView { return _sharedApplication; }
        public static function get sharedRepository():MainRepository { return _sharedApplication.repository; }

        override public function addChild(child:DisplayObject):DisplayObject {
            super.addChild(child);
            setChildIndex(cursor, numChildren - 1);
            return child;
        }

        override public function handleNavigationRequest(sender:Object):void {
            var commandName:String;
            var toViewName:String;
            var isRestoreRequest:Boolean = false;
            var isExitRequest:Boolean = false;
            // Handle natural navigation by matching to existing triggers:
            if (sender is Event) {
                // From root menu.
                if (rootMenuView != null) {
                    switch (sender.target) {
                        case rootMenuView.networkedGameButton:
                            toViewName = 'hostOrJoinGameView';
                            MainMenuView.sendCommand('lobbyScreen');
                            break;
                        case rootMenuView.tutorialButton:   MainMenuView.sendCommand('playTutorialInUdk'); break;
                        case rootMenuView.creditButton:     MainMenuView.sendCommand('showCreditInUdk'); break;
                        case rootMenuView.quitButton:       MainMenuView.sendCommand('quitGameInUdk'); break;
                        default: break;
                    }

                }
                // From host-or-join view.
                if (hostOrJoinGameView != null) {
                    switch (sender.target) {
                        case hostOrJoinGameView.joinButton:
                            toViewName = 'joinGameView';
                            var selectedModel:Object = hostOrJoinGameView.gameTableView.selectedModel;
                            gameModel.level = MainRepository.getById(selectedModel.level, levels);
                            gameModel.location = selectedModel.location;
                            MainMenuView.sendCommand('joinGameScreen');
                            break;
                        case hostOrJoinGameView.hostButton:
                            toViewName = 'hostGameView';
                            MainMenuView.sendCommand('hostGameScreen');
                            break;
                        default: break;
                    }
                }
                // From host view.
                if (hostGameView != null) {
                    switch (sender.target) {
                        case hostGameView.hostButton:
                            toViewName = 'joinGameView';
                            gameModel.level = hostGameView.levelSelectView.selectedModel;
                            MainMenuView.sendCommand('hostGameInUdk', gameModel.location);
                            MainMenuView.sendCommand('joinGameScreen_Host');
                            break;
                        default: break;
                    }
                }
                // From join view.
                if (joinGameView != null) {
                    switch (sender.target) {
                        case joinGameView.joinButton:
                            gameModel.level = joinGameView.levelPreview.model;
                            commandName = 'joinGameInUdk'.concat(
                                (previousView is HostGameView) ? '_Host' : '_NonHost'
                            );
                            MainMenuView.sendCommand(commandName, gameModel.location);
                            isExitRequest = true;
                            break;
                        default: break;
                    }
                }
            // Handle restores.
            } else if (sender is String) {
                isRestoreRequest = true;
                toViewName = sender as String;
            }
            // Exit if needed.
            if (isExitRequest) {
                if (shouldDebug) {
                    trace('EXIT');
                }
                return;
            }
            // Guard.
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
                    // Clone model.
                    var levelModel:Object = {};
                    for (var key:String in gameModel.level) {
                        if (key === 'image') {
                            levelModel.image = new Bitmap(gameModel.level.image.bitmapData);
                            continue;
                        }
                        levelModel[key] = gameModel.level[key];
                    }
                    if (levelModel.image == null) {
                        var classRef = LevelSelectView.getPreviewAssetClass(levelModel.id);
                        levelModel.image = new Bitmap(new classRef() as BitmapData);
                    }
                    joinGameView.levelPreview.model = levelModel;
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
            view.gameModel = gameModel;
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

        override protected function willPopView(view:MovieClip):void {
            super.willPopView(view);
            if (aggressiveMemoryManagement) {
                switch (view) {
                    case rootMenuView:          rootMenuView = null; break;
                    case hostOrJoinGameView:    hostOrJoinGameView = null; break;
                    case hostGameView:          hostGameView = null; break;
                    case joinGameView:          joinGameView = null; break;
                    default: break;
                }
            }
        }

        protected function addVersionLabel():void {
            var versionLabel:Label = new DefaultLabel();
            versionLabel.alpha = 0.3;
            versionLabel.autoSize = TextFieldAutoSize.RIGHT;
            versionLabel.text = MainMenuView.VERSION;
            versionLabel.visible = shouldDebug;
            versionLabel.x = stage.stageWidth - versionLabel.width - 3;
            addChild(versionLabel);
        }

        // Helpers.

        public static function sendCommand(name:String, value:String=''):void {
            if (!MainMenuView.SEND_COMMANDS) { return; }
            Utility.sendCommand(name, value);
        }

        // UDK data endpoints.

        // Proxy to repository.
        public function get games():Array { return repository.games; }
        public function set games(value:Array):void {
            repository.games = value;
            if (MainMenuView.DEBUG) { trace('GAMES', repository.games); }
        }
        public function get characters():Array { return repository.characters; }
        public function set characters(value:Array):void {
            repository.characters = value;
            if (MainMenuView.DEBUG) { trace('CHARACTERS', characters); }
        }
        public function get levels():Array { return repository.levels; }
        public function set levels(value:Array):void {
            repository.levels = value;
            if (MainMenuView.DEBUG) { trace('LEVELS', levels); }
        }

        public function get gameModel():GameModel { return _gameModel; }
        public function set gameModel(value:GameModel):void {
            _gameModel = value as GameModel;
            if (MainMenuView.DEBUG) { trace('GAME', gameModel); }
        }

        public function restore(toViewName:String, toGameModel:Object):void {
            gameModel = toGameModel as GameModel;
            handleNavigationRequest(toViewName);
        }

    }

}
