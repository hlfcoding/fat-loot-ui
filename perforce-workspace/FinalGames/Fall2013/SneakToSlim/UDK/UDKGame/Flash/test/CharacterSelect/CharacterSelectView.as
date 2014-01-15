package  {

	import flash.display.MovieClip;
	import fl.controls.TileList;
	import fl.data.DataProvider;

	public class CharacterSelectView extends MovieClip {


		public function CharacterSelectView() {
			// constructor code
			var characterMenu:TileList = TileList(this.getChildByName('CharacterMenu'));
			var characters:DataProvider = DataProvider(characterMenu.dataProvider);
			trace(characterMenu.columnWidth);
			trace(characters.toArray());
		}
	}

}
