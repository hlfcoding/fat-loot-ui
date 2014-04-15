package  {

    import scaleform.clik.events.ListEvent;

    public class CharacterSelectView extends SelectView {

        public var skillSelectView:SkillSelectView;

        public var gameModel:GameModel;

        [Embed(source='../Assets/character-fatlady.png')]       public static var FatLadyAsset:Class;
        [Embed(source='../Assets/character-ginsengbaby.png')]   public static var GinsengBabyAsset:Class;
        [Embed(source='../Assets/character-rabbit.png')]        public static var RabbitAsset:Class;
        [Embed(source='../Assets/character-shorty.png')]        public static var ShortyAsset:Class;

        [Embed(source='../Assets/character-preview-fatlady.png')]       public static var FatLadyPreviewAsset:Class;
        [Embed(source='../Assets/character-preview-ginsengbaby.png')]   public static var GinsengBabyPreviewAsset:Class;
        [Embed(source='../Assets/character-preview-rabbit.png')]        public static var RabbitPreviewAsset:Class;
        [Embed(source='../Assets/character-preview-shorty.png')]        public static var ShortyPreviewAsset:Class;

        public function CharacterSelectView() {
            super()
            // Configure.
            selectMenu.labelFunction = function(item:Object):String {
                var model:Object = item;
                return model.name;
            };
            skillSelectView.selectMenu.addEventListener(ListEvent.INDEX_CHANGE, onSkillSelect);
            // Commit.
            source = GameModel.characters;
            init();
        }

        override protected function getAssetClass(id:String, destination:Object):Class {
            if (destination === backgroundImages) {
                switch (id) {
                    case 'FatLady':     return CharacterSelectView.FatLadyAsset;
                    case 'GinsengBaby': return CharacterSelectView.GinsengBabyAsset;
                    case 'Rabbit':      return CharacterSelectView.RabbitAsset;
                    case 'Shorty':      return CharacterSelectView.ShortyAsset;
                    default: break;
                }
            } else if (destination === previewImages) {
                switch (id) {
                    case 'FatLady':     return CharacterSelectView.FatLadyPreviewAsset;
                    case 'GinsengBaby': return CharacterSelectView.GinsengBabyPreviewAsset;
                    case 'Rabbit':      return CharacterSelectView.RabbitPreviewAsset;
                    case 'Shorty':      return CharacterSelectView.ShortyPreviewAsset;
                    default: break;
                }
            }
            return Class;
        }

        override public function set selectedModel(value:Object):void {
            super.selectedModel = value;
            if (selectedModel != null) {
                skillSelectView.source = selectedModel.skills;
                MainMenuView.sendCommand('selectCharacterInUdk', selectedModel.id);
            }
        }

        public function onSkillSelect(event:ListEvent):void {
            if (event.type === ListEvent.INDEX_CHANGE) {
                var skill:Object = skillSelectView.getModelAtIndex(event.index);
                // We're just viewing the skill. There's no selection.
            }
        }

    }

}
