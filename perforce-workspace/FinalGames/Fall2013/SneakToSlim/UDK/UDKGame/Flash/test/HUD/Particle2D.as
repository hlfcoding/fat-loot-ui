/* ***********************************************************************
ActionScript 3 Effect by Dan Gries and Barbara Kaskosz

http://www.flashandmath.com/

Last modified: August 18, 2010
************************************************************************ */


package HUD {
	
	import flash.geom.Point;
	
	public class Particle2D extends Point {
		//links:
		public var next:Particle2D;
		
		//velocity and acceleration vectors
		public var vel:Point = new Point();
		public var accel:Point = new Point();
		
		//color attributes
		public var color:uint;
		public var red:uint;
		public var green:uint;
		public var blue:uint;
		public var alpha:uint;
		public var lum:Number;
		
		//A wildcard property that you can use in your application if you need it.
		public var wc:Number;
		
		public function Particle2D(thisColor=0xFFFFFFFF){
			
			this.color = thisColor;
			this.red = ((thisColor >> 16) & 0xFF);
			this.green = ((thisColor >> 8) & 0xFF);
			this.blue = (thisColor & 0xFF);
			this.alpha=((thisColor >> 24) & 0xFF);
			
			this.lum = 0.2126*this.red + 0.7152*this.green + 0.0722*this.blue;
		}
		
		
	}
}