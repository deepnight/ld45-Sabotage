package en;

class Mob extends Entity {
	public static var ALL : Array<Mob> = [];

	var patrolPts : Array<CPoint> = [];
	var lastAlarmPt : CPoint;
	var curPatrolIdx = 0;
	var curPatrolPt(get,never) : CPoint; inline function get_curPatrolPt() return patrolPts[curPatrolIdx];
	var path : Array<CPoint> = [];

	public var lookAng : Float;
	var viewCone : HSprite;

	public function new(x,y, data:ogmo.Entity) {
		super(x,y);
		ALL.push(this);
		lastAlarmPt = new CPoint(cx,cy);

		dir = Std.random(2)*2-1;
		lookAng = dirToAng();

		// Parse patrol
		if( data.nodes.length>0 ) {
			var lastPt = new CPoint(cx,cy);
			for(n in data.nodes) {
				var segment = [];
				dn.Bresenham.iterateThinLine( lastPt.cx, lastPt.cy, n.cx, n.cy, function(x,y) segment.push( new CPoint(x, y) ) );
				if( segment[0].cx!=lastPt.cx || segment[0].cy!=lastPt.cy )
					segment.reverse();
				patrolPts = patrolPts.concat(segment);
				lastPt.set(n.cx, n.cy);
			}
			var i = 0;
			while( i<patrolPts.length-1 ) {
				while( i<patrolPts.length-1 && patrolPts[i].cx==patrolPts[i+1].cx && patrolPts[i].cy==patrolPts[i+1].cy )
					patrolPts.splice(i,1);
				i++;
			}
			if( !patrolPts[0].is(cx,cy) )
				patrolPts.insert(0, new CPoint(cx,cy));
		}
		else {
			switch data.getStr("patrol") {
				case "up" :
					var to = cy;
					while( !level.hasCollision(cx,to-1) ) to--;
					patrolPts.push( new CPoint(cx,to) );
					var to = cy;
					while( !level.hasCollision(cx,to+1) ) to++;
					patrolPts.push( new CPoint(cx,to) );

				case "down" :
					var to = cy;
					while( !level.hasCollision(cx,to+1) ) to++;
					patrolPts.push( new CPoint(cx,to) );
					var to = cy;
					while( !level.hasCollision(cx,to-1) ) to--;
					patrolPts.push( new CPoint(cx,to) );

				case "left" :
					var to = cx;
					while( !level.hasCollision(to-1,cy) ) to--;
					patrolPts.push( new CPoint(to,cy) );
					var to = cx;
					while( !level.hasCollision(to+1,cy) ) to++;
					patrolPts.push( new CPoint(to,cy) );

				case "right" :
					var to = cx;
					while( !level.hasCollision(to+1,cy) ) to++;
					patrolPts.push( new CPoint(to,cy) );
					var to = cx;
					while( !level.hasCollision(to-1,cy) ) to--;
					patrolPts.push( new CPoint(to,cy) );
			}
		}
		if( patrolPts.length==0 )
			patrolPts.insert(0, new CPoint(cx,cy));

		// for(i in 0...patrolPts.length) fx.markerCase(patrolPts[i].cx, patrolPts[i].cy, 9999, Color.interpolateInt(0x000088,0x880000, i/patrolPts.length)); // HACK

		// Sight
		viewCone = Assets.tiles.h_get("viewCone",0, 0, 0.5);
		game.scroller.add(viewCone, Const.DP_MAIN);
		game.scroller.under(viewCone);
		viewCone.setScale(0.2);
		viewCone.blendMode = Add;

		// Anims
		spr.anim.registerStateAnim("guardGrabbed", 20, 0.1, function() return isGrabbed());
		spr.anim.registerStateAnim("guardHit", 10, 0.15, function() return isStunned());
		spr.anim.registerStateAnim("guardRun", 1, 0.2, function() return isMoving() && hasAlarm());
		spr.anim.registerStateAnim("guardWalk", 1, 0.2, function() return isMoving());
		spr.anim.registerStateAnim("guardIdle", 0, 0.4);
		initLife(3);
	}

	override function onDamage(dmg:Int) {
		super.onDamage(dmg);
		triggerAlarm();
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
		viewCone.remove();
		path = null;
		patrolPts = null;
	}

	override function onDie() {
		super.onDie();
		new en.Cadaver(this, "guardDead");
		for(e in ALL)
			if( e!=this && e.isAlive() && distCase(e)<=4 && sightCheckEnt(e) )
				e.triggerAlarm();
	}

	function goto(x,y) {
		if( !sightCheckCase(x,y) ) {
			path = level.pf.smooth( level.pf.getPath({x:cx, y:cy}, {x:x, y:y}) ).map( function(pt) return new CPoint(pt.x, pt.y) );
			path.shift();
		}
		else
			path = [ new CPoint(x,y) ];
	}

	override function postUpdate() {
		super.postUpdate();

		viewCone.x = footX;
		viewCone.y = footY;
		viewCone.visible = zr<=0.4 && !level.hasVisibleRoof(cx,cy) && !isGrabbed();

		viewCone.scaleX += ( ( hasAlarm() && sightCheckEnt(hero) ? 0.5 : 0.3 ) - viewCone.scaleX ) * 0.2;
		viewCone.scaleY += ( ( hasAlarm() && sightCheckEnt(hero) ? 0.2 : 0.3 ) - viewCone.scaleY ) * 0.2;
		viewCone.alpha += ( ( hasAlarm() ? 0.3 : 0.2 ) - viewCone.alpha ) * 0.2;
		if( !hasAlarm() || isStunned() )
			viewCone.rotation += M.radSubstract(lookAng,viewCone.rotation)*0.2 ;
		else if( sightCheckEnt(hero) )
			viewCone.rotation += M.radSubstract(angTo(hero),viewCone.rotation)*0.2 ;
		else
			viewCone.rotation += M.radSubstract(lookAng, viewCone.rotation ) * 0.2 ;
		viewCone.colorize( hasAlarm() ? sightCheckEnt(hero) ? 0xff0000 : 0xffdd00 : 0x7a9aff );

		if( !isStunned() && hasAlarm() && !cd.has("sawHero") && !cd.hasSetS("sweat",0.1) )
			fx.sweat(this);
	}

	function onAlarmStart() {}
	function onAlarmEnd() {
		var dh = new dn.DecisionHelper(patrolPts);
		dh.score( function(pt) return -distCaseFree(pt.cx, pt.cy) );
		var t = dh.getBest();
		goto(t.cx, t.cy);
		for(i in 0...patrolPts.length)
			if( patrolPts[i].is(t.cx,t.cy) )
				curPatrolIdx = i;
		if( !isStunned() && zr==0 )
			fx.question(headX, headY);
		lockS(0.4);
	}

	public inline function hasAlarm() {
		return isAlive() && cd.has("alarm");
	}

	public function triggerAlarm(?sec=3.0) {
		if( !hasAlarm() ) {
			onAlarmStart();
			lockS(0.4);
			cd.setS("recentAlarmStart", getLockS()+0.1);
		}
		lastAlarmPt.set(hero.cx, hero.cy, hero.xr, hero.yr);
		cd.setS("alarm",sec);
		cd.setS("wasUnderAlarm", Const.INFINITE);
	}


	override function onTouchWall(wallDirX:Int, wallDirY:Int) {
		super.onTouchWall(wallDirX, wallDirY);
		if( cd.has("violentThrow") ) {
			hit(99);
			fx.wallImpact(centerX, centerY, Math.atan2(wallDirY, wallDirX));
			cd.unset("violentThrow");
		}
		if( cd.has("punched") ) {
			hit(1);
			cancelVelocities();
			bump(-wallDirX*0.06, -wallDirY*0.06, 0.1);
			fx.wallImpact(centerX, centerY, Math.atan2(wallDirY, wallDirX));
			cd.unset("punched");
		}
	}


	override function update() {
		super.update();

		if( !hasAlarm() && cd.has("wasUnderAlarm") ) {
			onAlarmEnd();
			cd.unset("wasUnderAlarm");
		}

		// Mob collisions
		if( ( isMoving() || zr<0 ) && isStunned() )
			for(e in Mob.ALL)
				if( e!=this && e.isAlive() && distCase(e)<=1.3 && !e.cd.has("touchLock"+uid) && !cd.has("touchLock"+e.uid) ) {
					e.bumpAwayFrom(this, 0.1, 0.1);
					e.stunS(3);
					e.hit(e, cd.has("violentThrow") ? 2 : 1);
					e.triggerAlarm();
					e.cd.setS("touchLock"+uid, 1);
					if( cd.has("violentThrow") )
						hit(99);
					break;
				}

		if( isGrabbed() )
			cd.setS("sawHero", 1);

		if( !isGrabbed() ) {
			if( hero.isAlive() ) {
				// See hero
				var viewAng = hasAlarm() ? M.PI*0.8 : M.PI*0.4;
				var viewDist = hasAlarm() ? 11 : 6;
				if( ui.Console.ME.hasFlag("cone") ) {
					fx.angle(footX, footY, lookAng+viewAng*0.5, viewDist*Const.GRID, 0.03, 0xff0000);
					fx.angle(footX, footY, lookAng-viewAng*0.5, viewDist*Const.GRID, 0.03, 0xff0000);
				}
				if( sightCheckEnt(hero) && M.radDistance(angTo(hero),lookAng)<=viewAng*0.5 && distCase(hero)<=viewDist ) {
					cd.setS("sawHero", 0.5, false);
					cd.setS("canShoot", 0.3);
				}

				// Continue to track hero longer after last sight
				if( !isStunned() && cd.has("sawHero") ) {
					if( !hasAlarm() ) {
						fx.alarm(headX, headY+5);
						fx.flashBangS(0xffcc00, 0.3);
					}

					triggerAlarm();
				}

				// Shoot
				if( !isLocked() && cd.has("canShoot") && distCase(hero)<=8 && !cd.has("shootLock")) {
					lockS(0.3);
					var a = angTo(hero);
					// spr.anim.play(M.radDistance(a,1.57)<=0.8 ? "guardShootDown" : "guardShoot").setSpeed(0.2);
					spr.anim.play("guardShoot").setSpeed(0.2);
					dir = hero.centerX>centerX ? 1 : -1;
					game.delayer.addS(function() {
						if( !isAlive() || isStunned() )
							return;
						var e = new en.Bullet(this, a);
						fx.shoot(e.footX, e.footY-2, a, 0xff0000);
					},0.2);
					cd.setS("shootLock", 1);

					// for(e in ALL)
					// 	if( e!=this && e.isAlive() && distCase(e)<=6 && sightCheckEnt(e) && !e.hasAlarm() ) {
					// 		e.triggerAlarm();
					// 		e.cd.setS("sawHero",0.2);
					// 	}
				}
			}

			// Movement AI
			if( !hasAlarm() ) {
				if( !curPatrolPt.is(cx,cy) ) {
					// Patrol movement
					if( !cd.hasSetS("patrolPath",0.4) )
						goto(curPatrolPt.cx, curPatrolPt.cy);
				}
				else {
					// Reached patrol point
					curPatrolIdx++;
					cd.unset("patrolPath");
					if( curPatrolIdx>=patrolPts.length )
						curPatrolIdx = 0;
				}
			}
			else {
				// Track alarm source
				if( !cd.hasSetS("trackPath",0.2) ) {
					goto(lastAlarmPt.cx, lastAlarmPt.cy);
				}
			}


			// Follow path
			if( path.length>0 && !isLocked() ) {
				var next = path[0];
				while( next!=null && next.distCase(this)<=0.2 ) {
					path.shift();
					next = path[0];
				}
				if( next!=null ) {
					// Movement
					var s = hasAlarm() ? 0.008 : spr.frame==1 ? 0.003 : 0.006;
					var a = Math.atan2(next.footY-footY, next.footX-footX);
					dx+=Math.cos(a)*s*tmod;
					dy+=Math.sin(a)*s*tmod;

					// Try to stick to cell center
					var a = Math.atan2(0.5-yr, 0.5-xr);
					dx+=Math.cos(a)*0.001*tmod;
					dy+=Math.sin(a)*0.001*tmod;

					if( hasAlarm() )
						dir = lastAlarmPt.cx<cx ? -1 : lastAlarmPt.cx>cx ? 1 : dir;
					else
						dir = next.cx<cx ? -1 : next.cx>cx ? 1 : dir;

					if( hasAlarm() && distPxFree(lastAlarmPt.footX, lastAlarmPt.footY) >= Const.GRID*0.5 )
						lookAng = Math.atan2(lastAlarmPt.footY-footY, lastAlarmPt.footX-footX);

					if( !hasAlarm() && distPxFree(next.footX, next.footY) >= Const.GRID*0.5 )
						lookAng = Math.atan2(next.footY-footY, next.footX-footX);

				}
			}
		}


		// Sound emit fx
		if( level.hasVisibleRoof(cx,cy) && distCase(hero)<=10 ) {
			if( !hasAlarm() && !cd.hasSetS("soundFx", 1) )
				fx.emitSound(footX, footY);
			if( hasAlarm() && !cd.hasSetS("soundFxAlarm", 0.4) )
				fx.emitSound(footX, footY, 0xff0000);
		}
	}
}