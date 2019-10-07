package en;

class Hero extends Entity {
	var ca : dn.heaps.Controller.ControllerAccess;
	public var grabbedEnt: Null<Entity>;
	var throwAngle : Float;

	var permaItems : Map<ItemType, Bool> = new Map();

	public function new(x,y) {
		super(x,y);
		ca = Main.ME.controller.createAccess("hero");

		spr.anim.registerStateAnim("heroHit", 10, function() return isLocked() && cd.has("recentHit") );
		spr.anim.registerStateAnim("heroUseGun", 2, 0.05, function() return isLocked() && cd.has("usingGun") );
		spr.anim.registerStateAnim("heroThrow", 2, 0.10, function() return isLocked() && cd.has("throwingItem") );
		spr.anim.registerStateAnim("heroGrab", 2, function() return isLocked() && cd.has("grabbingItem") );
		spr.anim.registerStateAnim("heroRun", 1, 0.2, function() return isMoving());
		spr.anim.registerStateAnim("heroIdleBack", 0, 0.4, function() return cd.has("lookingBack"));
		spr.anim.registerStateAnim("heroIdle", 0, 0.4);

		initLife(3);
	}

	public function addPermaItem(k:ItemType) {
		switch k {
			case GoldKey, SilverKey:
				Assets.SFX.item0(1);

			case Heal:
				heal(maxLife);
				Assets.SFX.hero2(1);
				return;

			case _:
		}
		permaItems.set(k,true);
	}
	public function hasPermaItem(k) return permaItems.get(k)==true;


	override function hit(?from:Entity, dmg:Int) {
		if( isGrabbing(en.Mob) ) {
			grabbedEnt.hit(from, dmg);
			if( from!=null )
				bump(from.dirTo(this)*0.1, 0, 0);
			lockS(0.1);
		}
		else
			super.hit(from, dmg);
	}

	override function onDamage(dmg:Int) {
		super.onDamage(dmg);
		// releaseGrab();
		fx.flashBangS(0xff0000,0.3, 0.4);
		if( lastHitSource!=null ) {
			var a = lastHitAng;
			bump(Math.cos(a)*0.07, Math.sin(a)*0.01, 0.1);
		}
		lockS(0.3);
		cd.setS("recentHit", getLockS());
		Assets.SFX.hero0(1);
	}

	override function onDie() {
		super.onDie();
		new en.Cadaver(this, "heroDead");
		fx.flashBangS(0xff0000, 0.3, 2);
		game.delayer.addS("restart", function() game.startLevel(level.lid), 1);
	}

	override function dispose() {
		super.dispose();
		releaseGrab();
		ca.dispose();
	}

	public inline function isGrabbing<T:Entity>(c:Class<T>) return grabbedEnt!=null && grabbedEnt.isAlive() && Std.is(grabbedEnt, c);
	public inline function isGrabbingItem(k:ItemType) return isGrabbing(en.Item) && grabbedEnt.as(Item).item==k;
	public inline function consumeItemUse() if( isGrabbing(en.Item) ) grabbedEnt.as(Item).consumeUse();

	function releaseGrab() {
		if( grabbedEnt==null )
			return;

		if( !grabbedEnt.isAlive() || !isAlive() ) {
			grabbedEnt = null;
			return;
		}

		grabbedEnt.setPosCase(cx,cy,xr,yr);
		grabbedEnt.bump(dir*0.06, 0, 0.2);
		grabbedEnt.stunS(0.4);
		grabbedEnt.setSpriteOffset();
		grabbedEnt.spr.rotation = 0;
		grabbedEnt.cd.setS("grabLock",1);
		grabbedEnt = null;
		cd.setS("grabLock",0.5);
	}

	function throwGrab() {
		if( grabbedEnt==null || !grabbedEnt.isAlive() )
			return;

		var e = grabbedEnt;
		game.delayer.addS( function() {
			if( isAlive() && e.isAlive() ) {
				releaseGrab();
				var s = 0.4;
				e.bump(Math.cos(throwAngle)*s, Math.sin(throwAngle)*s, 0.03);
				e.cd.setS("violentThrow",1.2);
			}
		}, 0.1);
		lockS(0.2);
		grabbedEnt.stunS(1.2);
		grabbedEnt.cd.setS("grabLock",1);
		cd.setS("grabLock",0.5);
		throwAngle = getCleverAngle(false, e);
		cd.setS("throwingItem", getLockS()-0.1);
	}

	function grab(e:Entity) {
		Assets.SFX.item2(0.6);
		releaseGrab();
		dx*=0.3;
		dy*=0.3;
		dir = dirTo(e);
		e.cancelVelocities();
		grabbedEnt = e;
		lockS(0.09);
		cd.setS("grabbingItem", getLockS());

		if( e.is(Mob) )
			Assets.SFX.grab1(1);
		else
			Assets.SFX.grab4(1);
	}

	override function postUpdate() {
		super.postUpdate();

		if( grabbedEnt!=null ) {
			grabbedEnt.setPosCase(cx,cy,xr,yr);
			if( cd.has("grabbingItem") )
				grabbedEnt.setSpriteOffset(dir*10, 1);
			else if( cd.has("throwingItem") ) {
				grabbedEnt.spr.rotation = 0;
				grabbedEnt.setSpriteOffset(-dir*4, -8);
			}
			else if( cd.has("usingGun") ) {
				grabbedEnt.zPriorityOffset = 20;
				grabbedEnt.setSpriteOffset(dir*5, 2);
				grabbedEnt.dir = dir;
				grabbedEnt.spr.rotation = 0;
			}
			else if( isGrabbingItem(Knife) ) {
				grabbedEnt.zPriorityOffset = 20;
				if( cd.has("knifePunching") )
					grabbedEnt.setSpriteOffset(dir*10, -5);
				else
					grabbedEnt.setSpriteOffset(dir*5, -4);
				grabbedEnt.dir = dir;
				grabbedEnt.spr.rotation = 0;
			}
			else {
				if( isGrabbing(en.Item) ) {
					grabbedEnt.zPriorityOffset = -10;
					grabbedEnt.dir = dir;
					grabbedEnt.spr.rotation = dir*0.2;
					if( isMoving() )
						grabbedEnt.setSpriteOffset(-dir*2, -3);
					else
						grabbedEnt.setSpriteOffset(-dir*3, -2);

					if( isGrabbingItem(Gun) ) {
						grabbedEnt.sprOffX+=dir*4;
						grabbedEnt.sprOffY-=5;
						grabbedEnt.spr.rotation = dir*-1.3;
					}
				}
				else if( isGrabbing(en.Mob) ) {
					grabbedEnt.zPriorityOffset = 20;
					grabbedEnt.dir = dir;
					grabbedEnt.setSpriteOffset(dir*2, 1);
				}
			}
			grabbedEnt.postUpdate();
		}
	}

	function getCleverAngle(forEnemy:Bool, ?exclude:Entity) {
		var leftDist = M.dist(0,0, ca.lxValue(), ca.lyValue());
		var leftPushed = leftDist>=0.3;
		var leftAng = Math.atan2(-ca.lyValue(), ca.lxValue());

		var dh = new dn.DecisionHelper(Entity.ALL);
		// var dh = new dn.DecisionHelper(Mob.ALL);
		if( forEnemy )
			dh.keepOnly( function(e) return e.isAlive() && ( e.is(Mob) || e.is(Spike) && !e.as(Spike).broken || e.is(Item) && e.as(Item).item==Barrel ));
		else
			dh.keepOnly( function(e) return e.isAlive() && e.is(Mob) );
		dh.keepOnly( function(e) return e.isAlive() && ( exclude==null || e!=exclude ) && sightCheckEnt(e) && distCase(e)<=8 && !e.isGrabbed() );
		if( leftPushed )
			dh.remove( function(e) return M.radDistance(leftAng, angTo(e))>1 );
		dh.score( function(e) return isLookingAt(e) ? 10 : 0 );
		dh.score( function(e) return e.is(Mob) && e.as(Mob).hasAlarm() ? 3 : 0 );
		dh.score( function(e) return -distCase(e)*2 );
		if( leftPushed )
			dh.score( function(e) return M.radDistance(leftAng, angTo(e))<=0.7 ? 50 : 0 );

		var e = dh.getBest();
		if( e!=null ) {
			// fx.markerEntity(e, true);
			lookAt(e);
		}

		return e==null ? leftPushed ? leftAng : dirToAng() : angTo(e);
	}

	override function update() {
		super.update();

		var leftDist = M.dist(0,0, ca.lxValue(), ca.lyValue());
		var leftPushed = leftDist>=0.3;
		var leftAng = Math.atan2(-ca.lyValue(), ca.lxValue());

		// Throw aiming
		if( isLocked() && cd.has("throwingItem") ) {
			if( leftPushed )
				throwAngle = getCleverAngle(true);
			if( !cd.hasSetS("throwFx",0.02) )
				fx.throwAngle(footX, footY, throwAngle);
		}

		if( !isLocked() ) {
			// Move
			if( leftPushed ) {
				var s = 0.014 * leftDist * tmod * ( isGrabbing(Item) ? 1-grabbedEnt.as(Item).getSpeedReductionOnGrab() : 1.0 );
				dx+=Math.cos(leftAng)*s;
				dy+=Math.sin(leftAng)*s;
				if( ca.lxValue()<0.3 ) dir = -1;
				if( ca.lxValue()>0.3 ) dir = 1;
			}
			else {
				dx *= Math.pow(0.6,tmod);
				dy *= Math.pow(0.6,tmod);
			}

			// Pick perma item
			for(e in Item.ALL)
				if( e.isAlive() && e.isPermaItem() && distCase(e)<=e.getGrabDist() && sightCheckEnt(e) ) {
					addPermaItem(e.item);
					fx.pickPerma(e, e.item==Heal ? 0x1cdb83 : 0x2b5997);
					e.destroy();
				}

			if( grabbedEnt==null && !cd.has("grabLock") ) {
				// Pick item
				var dh = new dn.DecisionHelper(Item.ALL);
				dh.keepOnly( function(e) return e.canGrab() && distCase(e)<=e.getGrabDist() && sightCheckEnt(e) );
				dh.score( function(e) return -distCase(e) );
				var e = dh.getBest();
				if( e!=null )
					grab(e);
			}
			else if( ( ca.xPressed() || ca.aPressed() ) && grabbedEnt!=null ) {
				if( isGrabbing(Item) && grabbedEnt.as(Item).canUse() ) {
					var i = grabbedEnt.as(Item);
					switch i.item {
						case Barrel, Grenade:
							throwGrab();
							consumeItemUse();
							Assets.SFX.throw3(1);

						case Gun:
							// Shoot
							cancelVelocities();
							var a = getCleverAngle(false);
							new Bullet(this, a, 1.5);
							cd.setS("usingGun", 0.2);
							lockS(0.2);
							game.camera.shakeS(0.1, 0.2);
							consumeItemUse();
							Assets.SFX.throw0(1);

						case Knife, GoldKey, SilverKey, Heal:
					}
				}
				if( isGrabbing(Mob) )
					throwGrab();
			}
			else if( ca.bPressed() && grabbedEnt!=null )
				releaseGrab();

			#if debug
			if( ca.dpadUpPressed() ) {
				fx.explosion(centerX, centerY, Const.GRID*3);
			}
			#end

			// Punch/pick/use
			// if( ca.aPressed() ) {
			// 	lockS(0.2);
			// 	spr.anim.play("heroPunch").setSpeed(0.3);
			// 	bump(dir*0.02, 0, 0);
			// }
		}

		for(e in en.Mob.ALL) {
			if( !e.isAlive() )
				continue;

			if( isGrabbingItem(Knife) && distCase(e)<=0.8 && !e.cd.hasSetS("knifeHit", 0.2) ) {
				e.hit(this, 2);
				e.bumpAwayFrom(this, 0.1);
				e.stunS(1.5);
				fx.hit(e, dirTo(e));
				lockS(0.15);
				spr.anim.play("heroPunch").setSpeed(0.8);
				cd.setS("knifePunching",0.2);
				consumeItemUse();
			}

			if( grabbedEnt==null && !cd.has("grabLock") && !e.cd.has("grabLock") ) {
				// Grab mob
				if( ( !e.hasAlarm() || e.cd.has("allowLastSecondGrab") || e.isStunned() ) && distCase(e)<=0.75 ) {
					grab(e);
					break;
				}

				if( e.hasAlarm() && !e.cd.has("allowLastSecondGrab") && distCase(e)<=0.75 && !cd.has("punch") ) {
					// Melee punch
					lockS(0.3);
					cd.setS("punch",0.5);
					spr.anim.play("heroPunch").setSpeed(0.4);
					dir = dirTo(e);
					bump(dir*0.02, 0, 0);
					// var a = angTo(e);
					var a = getCleverAngle(true, e);
					e.stunS(1.2);
					e.bump(Math.cos(a)*0.4, Math.sin(a)*0.2, 0.15);
					// e.hit(this, 1);
					e.cd.setS("punched",0.4);
					game.camera.shakeS(0.2);
					break;
				}
			}
		}


		// Lost item
		if( grabbedEnt!=null && !grabbedEnt.isAlive() )
			grabbedEnt = null;

		// #if debug
		if( ca.yPressed() ) {
			Assets.SFX.explode0(1);
			trace("play 2");
		}
		// #end
		// 	dn.Bresenham.iterateDisc(cx,cy, 4, function(cx,cy) {
		// 		level.damage(cx,cy, 0.35);
			// });

		// Roof anim
		if( level.hasRoof(cx,cy) )
			level.eraseRoofFrom(cx,cy);
		else
			level.clearRoofErase();

		if( isMoving() )
			cd.setS("lookBackLock", 0.4);
		if( !isMoving() && zr==0 && !cd.has("lookBackLock") ) {
			cd.setS("lookingBack",0.5);
			cd.setS("lookBackLock",rnd(2.5,4));
		}

		if( ui.Console.ME.hasFlag("fps") ) debug(Std.int(hxd.Timer.fps()));
	}
}