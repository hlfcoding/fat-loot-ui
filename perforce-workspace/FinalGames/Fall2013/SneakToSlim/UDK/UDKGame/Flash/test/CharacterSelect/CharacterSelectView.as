package  {

    import scaleform.clik.controls.Label;
    import scaleform.clik.controls.TileList;
    import scaleform.clik.events.ListEvent;

    public class CharacterSelectView extends SelectView {

        public var skillSelectView:SkillSelectView;
        public var nameLabel:Label;

        public var gameModel:GameModel;

        public function CharacterSelectView() {
            super()
            // Configure.
            hasBackgroundImage = true;
            backgroundImagePathHandler = function(data:Object):String {
                return 'Assets'.concat('/character-', data.id.toLowerCase(), '.png');
            };
            skillSelectView.selectMenu.labelFunction =
            selectMenu.labelFunction = function(item:Object):String {
                var model:Object = item;
                return model.name;
            };
            skillSelectView.selectPreview.nameLabel.visible =
            selectPreview.nameLabel.visible = false;
            skillSelectView.selectMenu.addEventListener(ListEvent.INDEX_CHANGE, onSkillSelect);
            skillSelectView.selectPreview.imageSize = { width: 100, height: 100 };
            skillSelectView.selectPreview.imagePathHandler = function(data:Object):String {
                return 'Assets'.concat('/skill-', data.id.toLowerCase(), '.png');
            };
            skillSelectView.selectPreview.hasImage = true;

            // Commit.
            source = GameModel.characters;
            init();
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
