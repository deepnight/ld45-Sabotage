package en.mob;

class Guard extends en.Mob {
	public function new(data) {
		super(data);

		// Anims
		spr.anim.registerStateAnim("guardGrabbed", 20, 0.1, function() return isGrabbed());
		spr.anim.registerStateAnim("guardHit", 10, 0.15, function() return isStunned());
		spr.anim.registerStateAnim("guardRun", 1, 0.2, function() return isMoving() && hasAlarm());
		spr.anim.registerStateAnim("guardWalk", 1, 0.2, function() return isMoving());
		spr.anim.registerStateAnim("guardIdle", 0, 0.4);
		initLife(3);
	}

	override function onDie() {
		super.onDie();
		new en.Cadaver(this, "guardDead", loot);
	}

	override function postUpdate() {
		super.postUpdate();

		if( !isStunned() && hasAlarm() && !cd.has("sawHero") && !cd.hasSetS("sweat",0.1) )
			fx.sweat(this);
	}

	override function update() {
		super.update();

		if( hero.isAlive() ) {
			// See hero
			var viewAng = hasAlarm() ? M.PI*0.8 : M.PI*0.2;
			var viewDist = hasAlarm() ? 9 : 5;
			if( ui.Console.ME.hasFlag("cone") ) {
				fx.angle(footX, footY, lookAng+viewAng*0.5, viewDist*Const.GRID, 0.03, 0xff0000);
				fx.angle(footX, footY, lookAng-viewAng*0.5, viewDist*Const.GRID, 0.03, 0xff0000);
			}
			if( M.radDistance(angTo(hero),lookAng)<=viewAng*0.5 && distCase(hero)<=viewDist && sightCheckEnt(hero) ) {
				cd.setS("sawHero", 0.5, false);
			}

			// Continue to track hero longer after last sight
			if( !isStunned() && cd.has("sawHero") ) {
				if( !hasAlarm() )
					fx.alarm(this);

				triggerAlarm();
			}
		}

		// Shoot
		if( !isGrabbed() && !isLocked() && cd.has("sawHero") && distCase(hero)<=8 && !cd.has("shootLock")) {
			lockS(0.3);
			var a = angTo(hero);
			Assets.SFX.hit6(1);
			spr.anim.play("guardShoot").setSpeed(0.2);
			dir = hero.centerX>centerX ? 1 : -1;
			game.delayer.addS(function() {
				if( !isAlive() || isStunned() || isGrabbed() )
					return;
				var e = new en.Bullet(this, a);
				fx.shoot(e.footX, e.footY-2, a, 0xff0000);
			},0.2);
			cd.setS("shootLock", 1);
		}
	}
}