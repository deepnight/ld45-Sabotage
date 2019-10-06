package en;

class Hero extends Entity {
	var ca : dn.heaps.Controller.ControllerAccess;
	public var grabbedEnt: Null<Entity>;

	public function new(x,y) {
		super(x,y);
		ca = Main.ME.controller.createAccess("hero");

		spr.anim.registerStateAnim("heroHit", 10, function() return isLocked() && cd.has("recentHit") );
		spr.anim.registerStateAnim("heroUseGun", 2, 0.05, function() return isLocked() && cd.has("usingGun") );
		spr.anim.registerStateAnim("heroThrow", 2, 0.05, function() return isLocked() && cd.has("throwingItem") );
		spr.anim.registerStateAnim("heroGrab", 2, function() return isLocked() && cd.has("grabbingItem") );
		spr.anim.registerStateAnim("heroRun", 1, 0.2, function() return isMoving());
		spr.anim.registerStateAnim("heroIdleBack", 0, 0.4, function() return cd.has("lookingBack"));
		spr.anim.registerStateAnim("heroIdle", 0, 0.4);

		initLife(30);
	}


	override function hit(?from:Entity, dmg:Int) {
		if( isGrabbing(en.Mob) ) {
			var e = grabbedEnt;
			releaseGrab();
			e.hit(from, dmg);
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
	}

	override function onDie() {
		super.onDie();
		new en.Cadaver(this, "heroDead");
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
		if( grabbedEnt!=null && grabbedEnt.isAlive() ) {
			grabbedEnt.setPosCase(cx,cy,xr,yr);
			grabbedEnt.bump(dir*0.06, 0, 0.2);
			grabbedEnt.stunS(0.4);
			grabbedEnt.setSpriteOffset();
			grabbedEnt.spr.rotation = 0;
			grabbedEnt.cd.setS("grabLock",1);
			grabbedEnt = null;
			cd.setS("grabLock",0.5);
		}
	}

	function getThrowAngle() {
		var leftDist = M.dist(0,0, ca.lxValue(), ca.lyValue());
		return leftDist<=0.3 ? dir==1?0:M.PI : Math.atan2(-ca.lyValue(), ca.lxValue());
	}

	var throwAngle : Float;
	function throwGrab() {
		if( grabbedEnt==null || !grabbedEnt.isAlive() )
			return;

		var e = grabbedEnt;
		game.delayer.addS( function() {
			if( isAlive() && e.isAlive() ) {
				releaseGrab();
				var s = 0.4;
				e.bump(Math.cos(throwAngle)*s, Math.sin(throwAngle)*s, 0.03);
			}
		}, 0.25);
		lockS(0.3);
		grabbedEnt.stunS(1.2);
		grabbedEnt.cd.setS("grabLock",1);
		cd.setS("grabLock",0.5);
		throwAngle = getThrowAngle();
		cd.setS("throwingItem", getLockS()-0.1);
	}

	function grab(e:Entity) {
		releaseGrab();
		dx*=0.3;
		dy*=0.3;
		dir = dirTo(e);
		e.cancelVelocities();
		grabbedEnt = e;
		lockS(0.3);
		cd.setS("grabbingItem", getLockS()-0.1);
	}

	override function postUpdate() {
		super.postUpdate();

		if( grabbedEnt!=null ) {
			if( cd.has("grabbingItem") )
				grabbedEnt.setPosPixel(footX+dir*10, footY+1);
			else if( cd.has("throwingItem") ) {
				grabbedEnt.spr.rotation = 0;
				grabbedEnt.setPosPixel(footX-dir*4, footY-8);
			}
			else if( cd.has("usingGun") ) {
				grabbedEnt.zPriorityOffset = 10;
				grabbedEnt.setSpriteOffset(dir*5, 2);
				grabbedEnt.spr.rotation = 0;
			}
			else {
				grabbedEnt.setPosCase(cx,cy,xr,yr);
				if( isGrabbing(en.Item) ) {
					grabbedEnt.zPriorityOffset = -10;
					grabbedEnt.dir = dir;
					grabbedEnt.spr.rotation = dir*0.2;
					if( isMoving() )
						grabbedEnt.setSpriteOffset(-dir*2, -3);
					else
						grabbedEnt.setSpriteOffset(-dir*3, -2);

					if( isGrabbingItem(Gun) ) {
						grabbedEnt.sprOffX+=dir*6;
						grabbedEnt.sprOffY-=4;
						grabbedEnt.spr.rotation = dir*-1.3;
					}
				}
				else if( isGrabbing(en.Mob) ) {
					grabbedEnt.dir = dir;
					grabbedEnt.setSpriteOffset(dir*2, 1);
				}
			}
			grabbedEnt.postUpdate();
		}
	}

	override function update() {
		super.update();

		var leftDist = M.dist(0,0, ca.lxValue(), ca.lyValue());
		var leftPushed = leftDist>=0.3;
		var leftAng = Math.atan2(-ca.lyValue(), ca.lxValue());

		// Throw aiming
		if( isLocked() && cd.has("throwingItem") ) {
			if( leftPushed && cd.getS("throwingItem")>=0.1 )
				throwAngle = getThrowAngle();
			if( !cd.hasSetS("throwFx",0.02) )
				fx.throwAngle(footX, footY, getThrowAngle());
		}

		if( !isLocked() ) {
			// Move
			if( leftPushed ) {
				var s = 0.013 * leftDist * tmod;
				dx+=Math.cos(leftAng)*s;
				dy+=Math.sin(leftAng)*s;
				if( ca.lxValue()<0.3 ) dir = -1;
				if( ca.lxValue()>0.3 ) dir = 1;
			}
			else {
				dx *= Math.pow(0.6,tmod);
				dy *= Math.pow(0.6,tmod);
			}

			// Pick/throw items
			if( grabbedEnt==null && !cd.has("grabLock") ) {
				var dh = new dn.DecisionHelper(Item.ALL);
				dh.keepOnly( function(e) return e.isAlive() && !e.isGrabbed() && ( sightCheckEnt(e) && distCase(e)<=1 || distCase(e)<=0.7 ) && !e.cd.has("grabLock"));
				dh.score( function(e) return -distCase(e) );
				var e = dh.getBest();
				if( e!=null )
					grab(e);
			}
			else if( ca.xPressed() && grabbedEnt!=null ) {
				if( isGrabbing(Item) && grabbedEnt.as(Item).canUse() ) {
					var i = grabbedEnt.as(Item);
					switch i.item {
						case Barrel:
							throwGrab();
							consumeItemUse();

						case Gun:
							// Shoot
							cancelVelocities();
							var dh = new dn.DecisionHelper(Mob.ALL);
							dh.keepOnly( function(e) return e.isAlive() && sightCheckEnt(e) && distCase(e)<=8 );
							dh.score( function(e) return isLookingAt(e) ? 10 : 0 );
							dh.score( function(e) return e.hasAlarm() ? 3 : 0 );
							dh.score( function(e) return -distCase(e)*2 );
							dh.score( function(e) return leftPushed && M.radDistance(leftAng, angTo(e))<=0.8 ? 50 : 0 );
							var e = dh.getBest();
							if( e!=null )
								lookAt(e);

							var a = e==null ? leftPushed ? leftAng : dirToAng() : angTo(e);
							new Bullet(this, a, 1.5);
							cd.setS("usingGun", 0.2);
							lockS(0.2);
							game.camera.shakeS(0.1, 0.2);
							consumeItemUse();
					}
				}
				if( isGrabbing(Mob) )
					throwGrab();
			}
			else if( ca.bPressed() && grabbedEnt!=null )
				releaseGrab();

			// Punch/pick/use
			// if( ca.aPressed() ) {
			// 	lockS(0.2);
			// 	spr.anim.play("heroPunch").setSpeed(0.3);
			// 	bump(dir*0.02, 0, 0);
			// }
		}

		// Grab enemies
		if( grabbedEnt==null && !cd.has("grabLock") )
			for(e in en.Mob.ALL) {
				if( !e.isAlive() || e.cd.has("grabLock") )
					continue;

				// Grab mob
				if( ( !e.hasAlarm() || e.cd.has("recentAlarmStart") ) && distCase(e)<=0.5 ) {
					grab(e);
					break;
				}

				if( e.hasAlarm() && !e.cd.has("recentAlarmStart") && distCase(e)<=1 && !cd.has("punch") ) {
					// Melee punch
					lockS(0.3);
					cd.setS("punch",0.5);
					spr.anim.play("heroPunch").setSpeed(0.4);
					dir = dirTo(e);
					bump(dir*0.02, 0, 0);
					var a = angTo(e);
					e.stunS(0.9);
					e.bump(Math.cos(a)*0.4, Math.sin(a)*0.2, 0.15);
					// e.hit(this,1);
					game.camera.shakeS(0.2);
					break;
				}
			}


		// Lost item
		if( grabbedEnt!=null && !grabbedEnt.isAlive() )
			grabbedEnt = null;

		// if( ca.yPressed() )
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