package  {

    public class SkillSelectView extends SelectView {

        [Embed(source='../Assets/skill-bellybump.png')]     public static var BellyBumpAsset:Class;
        [Embed(source='../Assets/skill-burrow.png')]        public static var BurrowAsset:Class;
        [Embed(source='../Assets/skill-burst.png')]         public static var BurstAsset:Class;
        [Embed(source='../Assets/skill-charge.png')]        public static var ChargeAsset:Class;
        [Embed(source='../Assets/skill-earthdive.png')]     public static var EarthDiveAsset:Class;
        [Embed(source='../Assets/skill-overthere.png')]     public static var OverThereAsset:Class;
        [Embed(source='../Assets/skill-sprint.png')]        public static var SprintAsset:Class;
        [Embed(source='../Assets/skill-tigerroar.png')]     public static var TigerRoarAsset:Class;

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
                    case 'BellyBump':   return SkillSelectView.BellyBumpAsset;
                    case 'Burrow':      return SkillSelectView.BurrowAsset;
                    case 'Burst':       return SkillSelectView.BurstAsset;
                    case 'Charge':      return SkillSelectView.ChargeAsset;
                    case 'EarthDive':   return SkillSelectView.EarthDiveAsset;
                    case 'OverThere':   return SkillSelectView.OverThereAsset;
                    case 'Sprint':      return SkillSelectView.SprintAsset;
                    case 'TigerRoar':   return SkillSelectView.TigerRoarAsset;
                    default: break;
                }
            }
            return Class;
        }

    }

}
