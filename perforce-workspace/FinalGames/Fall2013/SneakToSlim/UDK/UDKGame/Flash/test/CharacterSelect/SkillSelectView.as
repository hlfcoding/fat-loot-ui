package  {

    public class SkillSelectView extends SelectView {

        public function SkillSelectView() {
            super()
            // Configure.
            selectMenu.labelFunction = function(item:Object):String {
                var model:Object = item;
                return model.name;
            };
            hasBackgroundImage = false;
            selectPreview.imageSize = { width: 100, height: 100 };
        }

        override public function set source(source:Array):void {
            previewImages = null; // We get our source piece-meal.
            super.source = source;
        }

        override protected function getAssetClass(id:String, destination:Object):Class {
            if (destination === previewImages) {
                switch (id) {
                    case 'BellyBump':   return BellyBumpAsset;
                    case 'Burrow':      return BurrowAsset;
                    case 'Burst':       return BurstAsset;
                    case 'Charge':      return ChargeAsset;
                    case 'EarthDive':   return EarthDiveAsset;
                    case 'OverThere':   return OverThereAsset;
                    case 'Sprint':      return SprintAsset;
                    case 'TigerRoar':   return TigerRoarAsset;
                    default: break;
                }
            }
            return Class;
        }

    }

}
