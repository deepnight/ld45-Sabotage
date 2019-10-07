package en.mob;

class Turret extends en.Mob {
	var shootCount = 0;

	public function new(data) {
		super(data);
		initLife(5);
		armor = true;
		bumpReduction = 1.0;
		spr.setCenterRatio(0.5,0.5);
		spr.anim.registerStateAnim("turret",0);
	}

	override function hit(?from:Entity, dmg:Int) {
		super.hit(from, M.imin(1,dmg));
	}

	override function onDie() {
		super.onDie();
		var rCase = 5;
		cd.setS("exploded", Const.INFINITE);
		fx.explosion(centerX, centerY, Const.GRID*(rCase-1));
		for(e in Mob.ALL)
			if( e.isAlive() && distCase(e)<=rCase && ( sightCheckEnt(e) || distCase(e)<=3 ) )
				e.hit(this, 99);

		for(e in Item.ALL)
			if( e.isAlive() && distCase(e)<=rCase && ( sightCheckEnt(e) || distCase(e)<=3 ) && !e.cd.has("exploded") )
				e.onExplosion(this);
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
			var e = new en.Bullet(this, a, 0.66);
			fx.shoot(e.footX, e.footY-2, a, 0xff0000);
			shootCount--;
		}
	}
}