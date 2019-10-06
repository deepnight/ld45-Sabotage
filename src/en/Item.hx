package en;

class Item extends Entity {
	public static var ALL : Array<Item> = [];
	public var item : ItemType;

	public var maxUses : Int;

	public function new(x,y,i:ItemType) {
		super(x,y);
		ALL.push(this);
		item = i;
		spr.set( switch item {
			case Barrel: "barrel";
			case Gun: "gun";
		});

		maxUses = switch i {
			case Barrel: 1;
			case Gun: 2;
		}
	}

	public function canUse() return isAlive() && isGrabbed() && !isDepleted();
	public function isDepleted() return maxUses<=0;

	public function consumeUse() {
		maxUses--;
		if( maxUses<=0 ) {
			cd.setS("grabLock",Const.INFINITE);
			switch item {
				case Barrel: cd.setS("trigger", 1);
				case _:
					cd.setS("selfDestructing", Const.INFINITE);
					cd.setS("selfDestruct", 0.2);
			}
		}
	}

	override function onZLand() {
		super.onZLand();
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	function selfDestruct() {
		fx.destroyItem(this);
		destroy();
	}

	function onTouchEntity(e:Entity) {
		trace(e);
		if( e.is(Mob) ) {
			var e = e.as(Mob);
			e.bump(dirTo(e)*0.15, 0, 0.2);
			e.stunS(0.4);
			e.triggerAlarm();
		}
	}

	override function update() {
		super.update();

		if( ( isMoving() || zr<0 ) && !cd.has("touchLock") )
			for(e in Entity.ALL)
				if( e!=this && e.isAlive() && distCase(e)<=1.3 && !e.cd.has("touchLock") ) {
					onTouchEntity(e);
					e.cd.setS("touchLock", 0.5);
					break;
				}

		if( isDepleted() && cd.has("selfDestructing") && !cd.has("selfDestruct") )
			selfDestruct();

		switch item {
			case Barrel:
				if( isDepleted() && !cd.has("trigger") )
					destroy();

			case Gun:
		}
	}
}
