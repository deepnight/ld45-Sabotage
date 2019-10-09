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

		initLife(e.maxLife);
		life = 0;
		showLifeChange(e.maxLife);

		var a = e.lastHitAng;
		if( e.lastHitSource!=null )
			bump(Math.cos(a)*rnd(0.2,0.3), Math.sin(a)*0.2, rnd(0.11,0.15));
		else
			bump(Math.cos(a)*rnd(0.1,0.2), Math.sin(a)*0.1, rnd(0.14,0.17));
		cd.setS("lootLock", Const.INFINITE);
	}

	override function onZLand() {
		super.onZLand();
		cd.setS("landed", Const.INFINITE);
		spr.setFrame(1);
		cd.unset("lootLock");
	}

	override function postUpdate() {
		super.postUpdate();
		if( !cd.has("landed") )
			fx.bloodTail(this, M.sign(dxTotal));
	}

	override function update() {
		super.update();


		// Mob collisions
		if( !cd.has("landed") )
			for(e in Mob.ALL)
				if( e.isAlive() && distCase(e)<=1.3 && !e.cd.has("touchLock") ) {
					e.bumpAwayFrom(this, 0.1, 0.1);
					e.stunS(3);
					e.hit(e,1);
					e.triggerAlarm();
					e.cd.setS("touchLock", 1);
					break;
				}

		if( loot!=null && !cd.has("lootLock") ) {
			var e = new Item(cx,cy, loot);
			e.setPosCase(cx,cy,xr,yr);
			e.bump(0,0, 0.15);
			e.cd.setS("grabLock",0.2);
			loot = null;
		}
	}
}