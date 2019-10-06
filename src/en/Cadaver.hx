package en;

class Cadaver extends Entity {
	public var loot : Null<ItemType>;
	public function new(e:Entity, sprId:String, ?l:ItemType) {
		super(0,0);
		loot = l;
		setPosCase(e.cx, e.cy, e.xr, e.yr);
		frict = 0.92;

		spr.set(sprId,0);
		dir = -e.lastHitDir;

		var a = e.lastHitAng;
		bump(Math.cos(a)*0.3, Math.sin(a)*0.2, rnd(0.2,0.3));
		cd.setS("lootLock", Const.INFINITE);
	}

	override function onZLand() {
		super.onZLand();
		// dz = 0;
		spr.setFrame(1);
		// if( !cd.hasSetS("releaseLoot", Const.INFINITE) )
			// cd.setS("lootLock",0.1);
		cd.unset("lootLock");
	}

	override function postUpdate() {
		super.postUpdate();
		// if( zr>=0.1 || dz>0 )
		// 	spr.setFrame(0);
		// else
		// 	spr.setFrame(1);
	}

	override function update() {
		super.update();
		if( loot!=null && !cd.has("lootLock") ) {
			var e = new Item(cx,cy, loot);
			e.setPosCase(cx,cy,xr,yr);
			e.bump(0,0, 0.15);
			e.cd.setS("grabLock",0.2);
			loot = null;
		}
	}
}