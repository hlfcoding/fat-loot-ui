package  {

    import flash.display.DisplayObject;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.utils.getTimer;

    import scaleform.clik.controls.ListItemRenderer;

    public class TableItemRenderer extends ListItemRenderer {

        public var extraPropertyNames:Vector.<String>;

        protected var extraTextFields:Vector.<TextField>;
        protected var extraLabels:Vector.<String>;
        protected var dividers:Vector.<TableItemDivider>;

        public var textField1:TextField;

        public function TableItemRenderer() {
            super();
            constraintsDisabled = true;
            autoSize = TextFieldAutoSize.NONE;
            updateExtraTextFields();
            updateExtraLabels();
            updateExtraText();
            updateDividers();
        }

        public function get cells():Vector.<TextField> {
            return new <TextField>[textField].concat(extraTextFields);
        }

        public function cellAt(index:uint):TextField {
            if (index === 0) {
                return textField;
            }
            return extraTextFields[index - 1];
        }

        public function updateUI():void {
            //trace(getTimer(), 'updateUI');
            updateExtraTextFields();
            updateExtraText();
            updateDividers();
        }

        protected function updateDividers():void {
            if (dividers == null) {
                dividers = new Vector.<TableItemDivider>();
                for (var index:uint = 0; index < numChildren; index++) {
                    var child:DisplayObject = getChildAt(index);
                    if (child is TableItemDivider) {
                        dividers.push(child);
                    }
                }
            }
            dividers.forEach(function(divider:TableItemDivider, index:int, vector:Vector.<TableItemDivider>):void {
                var textField:TextField = extraTextFields[index];
                divider.x = textField.x - 14;
                divider.visible = (data != null) ? data.hasDividers : false;
            }, this);
        }

        protected function updateExtraTextFields():void {
            // TODO: Optimize.
            extraTextFields = new <TextField>[];
            for (var index:uint = 1; index < numChildren; index++) {
                var child:DisplayObject = getChildAt(index);
                if (child is TextField && child !== textField) {
                    extraTextFields.push(child);
                }
            }
        }

        protected function updateExtraLabels():void {
            extraLabels = new <String>[];
            if (extraPropertyNames == null) {
                return;
            }
            extraPropertyNames.forEach(function(name:String, index:int, vector:Vector.<String>):void {
                extraLabels[index] = data[name];
            }, this);
        }

        protected function updateExtraText():void {
            extraTextFields.forEach(function(textField:TextField, index:int, vector:Vector.<TextField>):void {
                var defaultLabel:String = '';
                var label:String = defaultLabel;
                if (extraLabels.length > index) {
                    label = extraLabels[index];
                }
                textField.text = (label == null) ? defaultLabel : label;
            }, this);
        }

        override public function setData(data:Object):void {
            if (data == null) {
                return;
            }
            super.data = data;
            updateExtraLabels();
            updateUI();
        }

        override protected function updateAfterStateChange():void {
            super.updateAfterStateChange();
            updateUI();
        }

    }

}
