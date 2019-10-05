package en;

class Mob extends Entity {
	var patrolPts : Array<CPoint> = [];
	var curPatrolIdx = 0;
	var curPatrolPt(get,never) : CPoint; inline function get_curPatrolPt() return patrolPts[curPatrolIdx];

	public function new(x,y, data:ogmo.Entity) {
		super(x,y);
		for(n in data.nodes) {
			for(pt in patrolPts)
				if( pt.is(n.cx,n.cy) )
					throw "Duplicate patrol point for mob at "+cx+","+cy;
			patrolPts.push( new CPoint(n.cx, n.cy) );
		}

		if( patrolPts.length==0 || !patrolPts[0].is(cx,cy) )
			patrolPts.insert(0, new CPoint(cx,cy));
	}

	override function update() {
		super.update();

		if( M.dist(footX, footY, curPatrolPt.footX, curPatrolPt.footY)>Const.GRID*0.1 ) {
			// Patrol movement
			var s = 0.005;
			var a = Math.atan2(curPatrolPt.footY-footY, curPatrolPt.footX-footX);
			dx+=Math.cos(a)*s;
			dy+=Math.sin(a)*s;
		}
		else {
			// Reached patrol point
			curPatrolIdx++;
			if( curPatrolIdx>=patrolPts.length )
				curPatrolIdx = 0;
		}

		// Sound emit fx
		if( level.hasVisibleRoof(cx,cy) && !cd.hasSetS("soundFx", 1) )
			fx.emitSound(footX, footY);
	}
}