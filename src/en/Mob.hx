package en;

class Mob extends Entity {
	public static var ALL : Array<Mob> = [];

	var loot : Null<ItemType>;
	var patrolPts : Array<CPoint> = [];
	var lastAlarmPt : CPoint;
	var curPatrolIdx = 0;
	var curPatrolPt(get,never) : CPoint; inline function get_curPatrolPt() return patrolPts[curPatrolIdx];
	var path : Array<CPoint> = [];
	public var armor = false;


	public var lookAng : Float;
	var viewCone : HSprite;

	public function new(data:ogmo.Entity) {
		super(data.cx, data.cy);
		ALL.push(this);
		lastAlarmPt = new CPoint(cx,cy);

		if( data.getStr("loot","")!="" )
			loot = Type.createEnum(ItemType, data.getStr("loot"));


		dir = Std.random(2)*2-1;
		lookAng = dirToAng();

		if( data.getBool("static") ) {
			// Immobile
			patrolPts = [ new CPoint(cx,cy) ];
			dir = data.getStr("patrol")=="left" ? -1 : 1;
			lookAng = switch data.getStr("patrol") {
				case "up": -M.PIHALF;
				case "right": 0;
				case "down": M.PIHALF;
				case "left": M.PI;
				case _ : 0;
			}
		}
		else {
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
		}

		// for(i in 0...patrolPts.length) fx.markerCase(patrolPts[i].cx, patrolPts[i].cy, 9999, Color.interpolateInt(0x000088,0x880000, i/patrolPts.length)); // HACK

		// Sight
		viewCone = Assets.tiles.h_get("viewCone",0, 0, 0.5);
		game.scroller.add(viewCone, Const.DP_MAIN);
		game.scroller.under(viewCone);
		viewCone.setScale(0.2);
		viewCone.blendMode = Add;
	}

	override function onDamage(dmg:Int) {
		super.onDamage(dmg);
		triggerAlarm();
		alertAround(3);
		if( Std.random(2)==0 )
			Assets.SFX.mob3(1);
		else
			Assets.SFX.mob4(1);
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
		alertAround(5);
	}

	function alertAround(d) {
		for(e in ALL)
			if( e!=this && e.isAlive() && distCase(e)<=d && sightCheckEnt(e) )
				e.triggerAlarm();
	}

	override function canBeGrabbed():Bool {
		return isAlive() && !isGrabbed() && !cd.has("grabLock");
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
		viewCone.visible = zr<=0.4 && !level.hasVisibleRoof(cx,cy) && !isGrabbed() && !isStunned();

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
		// if( !isStunned() && zr==0 )
		// 	fx.question(headX, headY);
		lockS(0.4);
	}

	public inline function hasAlarm() {
		return isAlive() && cd.has("alarm");
	}

	public function triggerAlarm(?sec=6.0) {
		if( !hasAlarm() ) {
			onAlarmStart();
			lockS(0.4);
			// cd.setS("allowLastSecondGrab", getLockS()+0.1);
		}
		lastAlarmPt.set(hero.cx, hero.cy, hero.xr, hero.yr);
		cd.setS("alarm",sec);
		cd.setS("wasUnderAlarm", Const.INFINITE);
	}

	public function onPunch() {}

	override function onTouchWall(wallDirX:Int, wallDirY:Int) {
		super.onTouchWall(wallDirX, wallDirY);
		if( cd.has("violentThrow") ) {
			// hit(1);
			stunS(4);
			blink();
			mulVelocities(0.33);
			bump(-wallDirX*0.12, -wallDirY*0.12, 0.1);
			fx.wallImpact(centerX, centerY, Math.atan2(wallDirY, wallDirX), 0xff0000);
			cd.unset("violentThrow");
		}
		if( cd.has("punched") ) {
			// hit(1);
			stunS(2);
			blink();
			mulVelocities(0.33);
			bump(-wallDirX*0.04, -wallDirY*0.04, 0.1);
			fx.wallImpact(centerX, centerY, Math.atan2(wallDirY, wallDirX), 0x0088ff);
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
		if( ( isMoving() || zr<0 ) && isStunned() ) {
			for(e in Item.ALL)
				if( e.isAlive() && distCase(e)<=1.3 && e.item==Barrel ) {
					// cancelVelocities();
					bumpAwayFrom(e, 0.03);
					e.bumpAwayFrom(this,0.02);
					e.trigger(0.65);
					cd.setS("touchLock"+e.uid, 0.6);
				}

			for(e in Mob.ALL)
				if( e!=this && e.isAlive() && distCase(e)<=1.3 && !e.cd.has("touchLock") ) {
					bumpAwayFrom(e, 0.25, 0.1);
					e.bumpAwayFrom(this, 0.25, 0.1);
					e.stunS(3);
					// e.hit(e, 1);
					e.triggerAlarm();
					e.cd.setS("touchLock", 1);
					break;
				}
		}

		if( isGrabbed() )
			cd.setS("sawHero", 1);

		if( !isGrabbed() ) {
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
		if( distCase(hero)<=10 && level.hasVisibleRoof(cx,cy) ) {
			if( !hasAlarm() && !cd.hasSetS("soundFx", 1) )
				fx.emitSound(footX, footY);
			if( hasAlarm() && !cd.hasSetS("soundFxAlarm", 0.4) )
				fx.emitSound(footX, footY, 0xff0000);
		}
	}
}