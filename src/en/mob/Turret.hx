package en.mob;

class Turret extends en.Mob {
	var shootCount = 0;

	public function new(data) {
		super(data);
		initLife(5);
		bumpReduction = 1.0;
	}

	override function postUpdate() {
		super.postUpdate();
		spr.scaleX = sprScaleX; // no dir
		viewCone.visible = false;
	}

	override function canBeGrabbed():Bool {
		return false;
	}

	override function goto(x:Int, y:Int) {
		// nope
	}

	override function update() {
		super.update();
		var shootRange = 8;

		if( sightCheckEnt(hero) && distCase(hero)<=shootRange ) {
			if( !hasAlarm() )
				fx.alarm(this);
			triggerAlarm(1);
		}

		// Shoot
		if( hasAlarm() && !isLocked() && distCase(hero)<=shootRange && !cd.has("shootLock")) {
			lockS(0.3);
			cd.setS("shootLock", 1.5);
			shootCount = 3;
		}

		if( shootCount>0 && !cd.hasSetS("shoot",0.15) ) {
			var a = angTo(hero);
			Assets.SFX.hit6(1);
			var e = new en.Bullet(this, a);
			fx.shoot(e.footX, e.footY-2, a, 0xff0000);
			shootCount--;
		}
	}
}