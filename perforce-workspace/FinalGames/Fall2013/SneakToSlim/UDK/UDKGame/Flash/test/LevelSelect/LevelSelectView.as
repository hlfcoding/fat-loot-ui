package {

    import flash.events.Event;

    public class LevelSelectView extends SelectView {

        public var gameModel:GameModel;

        public static const SELECT:String = 'levelSelect';

        public function LevelSelectView() {
            super()
            // Configure.
            selectMenu.labelFunction = function(item:Object):String {
                var model:Object = item;
                return model.name;
            };
            // Commit.
            source = GameModel.levels;
            init();
        }

        override protected function getAssetClass(id:String, destination:Object):Class {
            if (destination === backgroundImages) {
                switch (id) {
                    case 'Mansion': return MansionAsset;
                    case 'Mist':    return MistAsset;
                    case 'Pit':     return PitAsset;
                    case 'Temple':  return TempleAsset;
                    case 'Vault':   return VaultAsset;
                    default: break;
                }
            } else if (destination === previewImages) {
                return LevelSelectView.getPreviewAssetClass(id);
            }
            return Class;
        }

        public static function getPreviewAssetClass(id:String):Class {
            switch (id) {
                case 'Mansion': return MansionPreviewAsset;
                case 'Mist':    return MistPreviewAsset;
                case 'Pit':     return PitPreviewAsset;
                case 'Temple':  return TemplePreviewAsset;
                case 'Vault':   return VaultPreviewAsset;
                default: break;
            }
            return Class;
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
