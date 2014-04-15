package {

    import flash.events.Event;

    public class LevelSelectView extends SelectView {

        public var gameModel:GameModel;

        public static const SELECT:String = 'levelSelect';

        [Embed(source='../Assets/level-mansion.png')]   public static var MansionAsset:Class;
        [Embed(source='../Assets/level-mist.png')]      public static var MistAsset:Class;
        [Embed(source='../Assets/level-pit.png')]       public static var PitAsset:Class;
        [Embed(source='../Assets/level-temple.png')]    public static var TempleAsset:Class;

        [Embed(source='../Assets/level-preview-mansion.png')]   public static var MansionPreviewAsset:Class;
        [Embed(source='../Assets/level-preview-mist.png')]      public static var MistPreviewAsset:Class;
        [Embed(source='../Assets/level-preview-pit.png')]       public static var PitPreviewAsset:Class;
        [Embed(source='../Assets/level-preview-temple.png')]    public static var TemplePreviewAsset:Class;

        public function LevelSelectView() {
            super()
            // Configure.
            hasBackgroundImage = true;
            backgroundImagePathHandler = function(data:Object):String {
                return 'Assets'.concat('/level-', data.id.toLowerCase(), '.png');
            };
            selectMenu.labelFunction = function(item:Object):String {
                var model:Object = item;
                return model.name;
            };
            selectPreview.nameLabel.visible = false;
            // Commit.
            source = GameModel.levels;
            init();
        }

        override public function set selectedModel(value:Object):void {
            super.selectedModel = value;
            if (selectedModel != null) {
                MainMenuView.sendCommand('selectGameMapInUdk', selectedModel.id);
            }
            dispatchEvent(new Event(LevelSelectView.SELECT));
        }

    }

}
