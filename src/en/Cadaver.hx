package en;

class Cadaver extends Entity {
	public function new(e:Entity, sprId:String) {
		super(0,0);
		setPosCase(e.cx, e.cy, e.xr, e.yr);
		frict = 0.92;

		spr.set(sprId,0);

		var a = e.lastHitAng;
		bump(Math.cos(a)*0.3, Math.sin(a)*0.2, rnd(0.2,0.3));
	}

	override function onZLand() {
		super.onZLand();
		// dz = 0;
		spr.setFrame(1);
	}

	override function postUpdate() {
		super.postUpdate();
		// if( zr>=0.1 || dz>0 )
		// 	spr.setFrame(0);
		// else
		// 	spr.setFrame(1);
	}
}