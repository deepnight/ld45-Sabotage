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

	function onSelfDestruct() {
		fx.destroyItem(this);
		destroy();
	}

	override function onTouchEntity(e:Entity, violent:Bool) {
		super.onTouchEntity(e, violent);

		if( violent && e.is(Mob) ) {
			onTrigger();
		}
	}

	function onTrigger() {
		switch item {
			case Barrel:
				var r = 5;
				fx.explosion(centerX, centerY, Const.GRID*(r-1));
				for(e in Mob.ALL)
					if( e.isAlive() && distCase(e)<=r && sightCheckEnt(e) ) {
						e.hit(this, 5);
					}
			case Gun:
		}
		destroy();
	}

	override function update() {
		super.update();

		if( isDepleted() && cd.has("selfDestructing") && !cd.has("selfDestruct") )
			onSelfDestruct();


		switch item {
			case Barrel:
				if( isDepleted() && !cd.has("trigger") )
					onTrigger();

			case Gun:
		}
	}
}
