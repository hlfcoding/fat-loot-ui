package  {

    import scaleform.clik.events.ListEvent;

    public class CharacterSelectView extends SelectView {

        public var skillSelectView:SkillSelectView;

        public var gameModel:GameModel;

        public function CharacterSelectView() {
            super()
            // Configure.
            selectMenu.labelFunction = function(item:Object):String {
                var model:Object = item;
                return model.name;
            };
            skillSelectView.selectMenu.addEventListener(ListEvent.INDEX_CHANGE, onSkillSelect);
            // Commit.
            source = MainMenuView.sharedApplication.characters;
            init();
        }

        override protected function getAssetClass(id:String, destination:Object):Class {
            if (destination === backgroundImages) {
                switch (id) {
                    case 'FatLady':     return FatLadyAsset;
                    case 'GinsengBaby': return GinsengBabyAsset;
                    case 'Rabbit':      return RabbitAsset;
                    case 'Shorty':      return ShortyAsset;
                    default: break;
                }
            } else if (destination === previewImages) {
                switch (id) {
                    case 'FatLady':     return FatLadyPreviewAsset;
                    case 'GinsengBaby': return GinsengBabyPreviewAsset;
                    case 'Rabbit':      return RabbitPreviewAsset;
                    case 'Shorty':      return ShortyPreviewAsset;
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
