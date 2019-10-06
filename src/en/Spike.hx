package en;

class Spike extends Entity {
	public static var ALL : Array<Spike> = [];

	public function new(x,y) {
		super(x,y);
		ALL.push(this);
		hasCollisions = false;
		spr.set("spike");
		disableShadow();
	}

	function hasSpike(x,y) {
		for(e in ALL)
			if( e.at(x,y) )
				return true;
		return false;
	}

	override function dispose() {
		super.dispose();
	}
	override function postUpdate() {
		super.postUpdate();
	}

	override function update() {
		if( !cd.hasSetS("initDone", Const.INFINITE) ) {
			if( level.hasCollision(cx,cy+1) && !hasSpike(cx,cy-1) ) {
				yr = 1;
			}
			else if( level.hasCollision(cx,cy-1) && !hasSpike(cx,cy+1) ) {
				yr = 0;
				spr.rotation = M.PI;
				sprOffY = -2;
			}
			else if( level.hasCollision(cx-1,cy) ) {
				xr = 0;
				spr.rotation = M.PIHALF;
			}
			else if( level.hasCollision(cx+1,cy) ) {
				xr = 1;
				spr.rotation = -M.PIHALF;
			}
		}

		cancelVelocities();
		super.update();

		for(e in Mob.ALL)
			if( e.isAlive() && distCase(e)<=1 && !e.cd.has("spikeHit") && ( e.isStunned() || e.cd.has("violentThrow") ) ) {
				e.hit(this, 99);
				e.stunS(1);
				fx.wallImpact(centerX, centerY, angTo(e));
				e.cancelVelocities();
				e.bumpAwayFrom(this, 0.07);
				e.cd.setS("spikeHit",0.4);
				spr.set("spikeBlood");
			}
	}
}
