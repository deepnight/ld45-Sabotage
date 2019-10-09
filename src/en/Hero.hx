package en;

class Hero extends Entity {
	var ca : dn.heaps.Controller.ControllerAccess;
	public var grabbedEnt: Null<Entity>;
	var throwAngle : Float;

	var permaItems : Map<ItemType, Bool> = new Map();

	var ammoBar : Null<h2d.Flow>;

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

		ammoBar = new h2d.Flow();
		game.scroller.add(ammoBar, Const.DP_UI);
		ammoBar.visible = false;
		ammoBar.verticalAlign = Middle;
		ammoBar.horizontalSpacing = 1;
		ammoBar.verticalAlign = Middle;

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
		game.hud.invalidate();
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
		game.delayer.addS("restart", function() game.restartLevel(), 1);
	}

	override function dispose() {
		super.dispose();
		releaseGrab();
		ca.dispose();
	}

	public inline function isGrabbing<T:Entity>(c:Class<T>) return grabbedEnt!=null && grabbedEnt.isAlive() && Std.is(grabbedEnt, c);
	public inline function isGrabbingItem(k:ItemType) return isGrabbing(en.Item) && grabbedEnt.as(Item).item==k;
	public inline function consumeItemUse() {
		if( isGrabbing(en.Item) ) {
			grabbedEnt.as(Item).consumeUse();
			updateAmmo();
		}
	}

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
		// cd.setS("grabLock",0.5);
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
		// cd.setS("grabLock",0.5);
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
		cd.setS("grabbingItem", 0.3);

		if( e.is(Mob) )
			Assets.SFX.grab1(1);
		else
			Assets.SFX.grab4(1);

		if( e.is(Item) ) {
			var i = e.as(Item);
			i.onGrab();
			updateAmmo();
		}
	}

	function updateAmmo() {
		if( !isGrabbing(Item) )
			return;
		var i = grabbedEnt.as(Item);
		ammoBar.removeChildren();
		for(n in 0...i.maxUses) {
			var a = Assets.tiles.h_get("pixel", ammoBar);
			a.alpha = n+1<=i.uses ? 1 : 0.2;
			a.scaleY = 2;
		}
	}

	override function postUpdate() {
		super.postUpdate();

		if( grabbedEnt!=null ) {
			grabbedEnt.setPosCase(cx,cy,xr,yr);
			if( cd.has("grabbingItem") ) {
				grabbedEnt.setSpriteOffset(dir*4, 1);
				grabbedEnt.zPriorityOffset = 20;
				if( !grabbedEnt.cd.hasSetS("blinkGrab",1) )
					grabbedEnt.blink();
			}
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

		ammoBar.x = Std.int( spr.x - ammoBar.outerWidth*0.5 );
		ammoBar.y = Std.int( spr.y - hei - ammoBar.outerHeight );
		ammoBar.visible = grabbedEnt!=null && grabbedEnt.is(Item) && grabbedEnt.as(Item).maxUses>1;

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
		if( leftPushed && !ca.isKeyboard() )
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

			// Auto pick perma items
			for(e in Item.ALL)
				if( e.isAlive() && e.isPermaItem() && !e.cd.has("autoPickLock") && distCase(e)<=1 && sightCheckEnt(e) ) {
					var e = e.as(Item);
					addPermaItem(e.item);
					fx.pickPerma(e, e.item==Heal ? 0x1cdb83 : 0x2b5997);
					e.destroy();
				}

			// Grab item/mob
			if( ca.aPressed() && !cd.has("grabLock") && grabbedEnt==null ) {
				var dh = new dn.DecisionHelper(Entity.ALL);
				dh.keepOnly( function(e) return e.canBeGrabbed() && distCase(e)<=Const.GRAB_REACH && sightCheckEnt(e) );
				dh.score( function(e) return -distCase(e) );
				dh.score( function(e) return e.is(Item) ? 1 : 0 );
				var e = dh.getBest();
				if( e!=null )
					grab(e);
				else {
					spr.anim.play("heroGrab").setSpeed(0.2);
					lockS(0.06);
				}
			}
			else if( ca.aPressed() && grabbedEnt!=null ) {
				// Use item
				if( isGrabbing(Item) && grabbedEnt.as(Item).canUse() ) {
					var i = grabbedEnt.as(Item);
					switch i.item {
						case Barrel, Grenade, ItchIo:
							throwGrab();
							consumeItemUse();
							Assets.SFX.throw3(1);

						case Gun:
							// Shoot
							cancelVelocities();
							var a = getCleverAngle(false);
							new Bullet(this, a, 2);
							cd.setS("usingGun", 0.2);
							lockS(0.2);
							game.camera.shakeS(0.1, 0.3);
							consumeItemUse();
							Assets.SFX.throw0(1);

						case Knife:
							lockS(0.15);
							spr.anim.play("heroPunch").setSpeed(0.8);
							cd.setS("knifePunching",0.1);
							var any = false;
							for(e in Mob.ALL) {
								if( e.isAlive() && distCase(e)<=Const.MELEE_REACH && sightCheckEnt(e) ) {
									if( e.armor )
										e.blink();
									else
										e.hit(this, 2);
									e.bumpAwayFrom(this, 0.1);
									e.stunS(1.5);
									fx.hit(e, dirTo(e));
									any = true;
								}
							}
							for(e in Item.ALL) {
								if( e.isAlive() && distCase(e)<=Const.MELEE_REACH && sightCheckEnt(e) ) {
									e.bumpAwayFrom(this, 0.1);
									if( e.onPunch(true) )
										any = true;
								}
							}
							if( any )
								consumeItemUse();


						case GoldKey, SilverKey, Heal:
					}
				}
				if( isGrabbing(Mob) )
					throwGrab();
			}
			else if( ca.bPressed() && grabbedEnt!=null )
				releaseGrab();


			// Melee punch
			// if( ca.aPressed() && grabbedEnt==null && !cd.has("punch") ) {
			// 	lockS(0.2);
			// 	spr.anim.play("heroPunch").setSpeed(0.4);
			// 	for(e in Mob.ALL) {
			// 		if( e.isAlive() && distCase(e)<=Const.MELEE_REACH && sightCheckEnt(e) ) {
			// 			dir = dirTo(e);
			// 			bump(dir*0.02, 0, 0);
			// 			e.blink(0xffffff);
			// 			var a = getCleverAngle(true, e);
			// 			e.stunS(1.1);
			// 			e.bump(Math.cos(a)*0.4, Math.sin(a)*0.2, 0.05);
			// 			e.cd.setS("punched",0.4);
			// 			e.onPunch();
			// 			game.camera.shakeS(0.2, 0.2);
			// 		}
			// 	}
			// 	for(e in Item.ALL) {
			// 		if( e.isAlive() && distCase(e)<=Const.MELEE_REACH && sightCheckEnt(e) ) {
			// 			e.bumpAwayFrom(this, 0.1);
			// 			e.onPunch(false);
			// 		}
			// 	}
			// }

			#if debug
			if( ca.dpadUpPressed() ) {
				fx.explosion(centerX, centerY, Const.GRID*3);
			}
			#end
		}

		// Bump into enemies
		for(e in en.Mob.ALL) {
			if( !e.isAlive() || distCase(e)>0.5 || e.isGrabbed() )
				continue;
			if( !cd.hasSetS("mobBump",0.03) ) {
				bumpAwayFrom(e, 0.05, 0);
				e.bumpAwayFrom(this, 0.02, 0);
				e.triggerAlarm();
			}
		}


		// Lost item
		if( grabbedEnt!=null && !grabbedEnt.isAlive() )
			grabbedEnt = null;

		#if debug
		if( ca.yPressed() ) {
			Assets.SFX.explode0(1);
		}
		#end

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

		if( ui.Console.ME.hasFlag("fps") ) debug(Std.int(hxd.Timer.fps())+" tmod="+pretty(tmod,2));
	}
}