package en;

class Hero extends Entity {
	var ca : dn.heaps.Controller.ControllerAccess;
	public function new(x,y) {
		super(x,y);
		ca = Main.ME.controller.createAccess("hero");
	}

	override function dispose() {
		super.dispose();
		ca.dispose();
	}

	override function update() {
		super.update();

		var leftDist = M.dist(0,0, ca.lxValue(), ca.lyValue());
		if( leftDist>=0.3 ) {
			var a = Math.atan2(-ca.lyValue(), ca.lxValue());
			var s = 0.01 * leftDist * tmod;
			dx+=Math.cos(a)*s;
			dy+=Math.sin(a)*s;
		}

		if( ca.xPressed() )
			dn.Bresenham.iterateDisc(cx,cy, 4, function(cx,cy) {
				level.damage(cx,cy, 0.35);
			});

		if( level.hasRoof(cx,cy) )
			level.eraseRoofFrom(cx,cy);
		else
			level.clearRoofErase();

		debug(fx.pool.getAllocateds());
	}
}