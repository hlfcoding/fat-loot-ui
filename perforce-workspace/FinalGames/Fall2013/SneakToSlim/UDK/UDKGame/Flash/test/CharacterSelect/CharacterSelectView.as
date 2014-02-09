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
            skillSelectView.selectMenu.labelFunction =
            selectMenu.labelFunction = function(item:Object):String {
                var model:Object = item;
                return model.name;
            };
            skillSelectView.selectPreview.nameLabel.visible =
            selectPreview.nameLabel.visible = false;
            skillSelectView.selectMenu.addEventListener(ListEvent.INDEX_CHANGE, onSkillSelect);
            // Commit.
            source = GameModel.CHARACTERS;
            init();
        }

        override public function set selectedModel(value:Object):void {
            super.selectedModel = value;
            if (selectedModel != null) {
                skillSelectView.source = selectedModel.skills;
                Utility.sendCommand('characterSelect', 'selectCharacterInUdk', selectedModel.id);
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
