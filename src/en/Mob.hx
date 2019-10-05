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

		// Parse patrol
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
		if( patrolPts.length==0 || !patrolPts[0].is(cx,cy) )
			patrolPts.insert(0, new CPoint(cx,cy));

		// for(i in 0...patrolPts.length) fx.markerCase(patrolPts[i].cx, patrolPts[i].cy, 9999, Color.interpolateInt(0x000088,0x880000, i/patrolPts.length)); // HACK

		viewCone = Assets.tiles.h_get("viewCone",0, 0, 0.5);
		game.scroller.add(viewCone, Const.DP_FX_BG);
		viewCone.setScale(0.2);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	public function hasAlarm() {
		return cd.has("alarm");
	}

	function goto(x,y) {
		path = level.pf.smooth( level.pf.getPath({x:cx, y:cy}, {x:x, y:y}) ).map( function(pt) return new CPoint(pt.x, pt.y) );
		path.shift();
	}

	override function postUpdate() {
		super.postUpdate();

		viewCone.x = footX;
		viewCone.y = footY;
		viewCone.visible = !level.hasVisibleRoof(cx,cy);

		viewCone.scaleX += ( ( hasAlarm() && sightCheckEnt(hero) ? 0.5 : 0.3 ) - viewCone.scaleX ) * 0.2;
		viewCone.scaleY += ( ( hasAlarm() && sightCheckEnt(hero) ? 0.2 : 0.3 ) - viewCone.scaleY ) * 0.2;
		viewCone.alpha += ( ( hasAlarm() ? 0.3 : 0.5 ) - viewCone.alpha ) * 0.2;
		if( !hasAlarm() )
			viewCone.rotation += M.radSubstract(lookAng,viewCone.rotation)*0.2 ;
		else if( sightCheckEnt(hero) )
			viewCone.rotation += M.radSubstract(angTo(hero),viewCone.rotation)*0.2 ;
		else
			viewCone.rotation += M.radSubstract(lookAng, viewCone.rotation ) * 0.2 ;
		viewCone.colorize( hasAlarm() ? sightCheckEnt(hero) ? 0xff0000 : 0xffdd00 : 0x7a9aff );
	}


	override function update() {
		super.update();

		// See hero
		if( sightCheckEnt(hero) && M.radDistance(angTo(hero),lookAng)<=M.PI*0.3 )
			cd.setS("sawHero", 0.5);

		if( cd.has("sawHero") ) {
			lastAlarmPt.set(hero.cx, hero.cy, hero.xr, hero.yr);
			cd.setS("alarm",3);
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
			if( !cd.hasSetS("trackPath",0.2) )
				goto(lastAlarmPt.cx, lastAlarmPt.cy);
			var a = Math.atan2(lastAlarmPt.footY-footY, lastAlarmPt.footX-footX);
			if( distPxFree(lastAlarmPt.footX,lastAlarmPt.footY)>=Const.GRID*0.5 )
				lookAng = a;
		}

		if( path.length>0 ) {
			// Follow path
			var next = path[0];
			while( next!=null && next.distCase(this)<=0.2 ) {
				path.shift();
				next = path[0];
			}
			if( next!=null ) {
				// Movement
				var s = hasAlarm() ? 0.008 : 0.005;
				var a = Math.atan2(next.footY-footY, next.footX-footX);
				fx.markerCase(next.cx, next.cy, 0.06, 0xffcc00);
				dx+=Math.cos(a)*s;
				dy+=Math.sin(a)*s;
				if( M.dist(footX, footY, next.footX, next.footY)>=Const.GRID*0.6 )
					lookAng = a;
				// Try to stick to cell center
				var a = Math.atan2(0.5-yr, 0.5-xr);
				dx+=Math.cos(a)*0.001;
				dy+=Math.sin(a)*0.001;
			}
		}


		// Sound emit fx
		if( level.hasVisibleRoof(cx,cy) && !cd.hasSetS("soundFx", 1) && distCase(hero)<=10 )
			fx.emitSound(footX, footY);
	}
}