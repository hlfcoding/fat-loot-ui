package  {

    import flash.display.MovieClip;

    import scaleform.clik.controls.Button;
    import scaleform.clik.events.ButtonEvent;
    import scaleform.clik.events.ListEvent;

    public class HostOrJoinGameView extends MovieClip implements IPresentableView {

        public var backButton:Button;
        public var hostButton:Button;
        public var joinButton:Button;
        public var refreshButton:Button;
        public var gameTableView:GameTableSelectView;

        public var gameModel:GameModel;

        public function HostOrJoinGameView() {
            super();
            joinButton.enabled = false;
            gameTableView.selectMenu.addEventListener(ListEvent.INDEX_CHANGE, onGameSelect);
            refreshButton.addEventListener(ButtonEvent.CLICK, handleRefresh);
        }

        public function get navigationBackButton():Button {
            return backButton;
        }
        public function get navigationButtons():Vector.<Button> {
            return new <Button>[hostButton, joinButton];
        }

        public function viewWillAppear():void {}
        public function viewDidAppear():void {}
        public function viewWillDisappear():void {}
        public function viewDidDisappear():void {}

        public function onGameSelect(event:ListEvent):void {
            joinButton.enabled = true;
        }

        public function handleRefresh(event:ButtonEvent):void {
            Utility.sendCommand('requestGamesInUdk');
        }

    }

}
