package en;

class Exit extends Entity {
	public function new(x,y) {
		super(x,y);
		disableShadow();
		spr.set("exit");
		spr.setCenterRatio(0.5,0.5);
		hasCollisions = false;
		level.specialEndingCondition = true;
	}

	override function update() {
		super.update();
		if( hero.at(cx,cy) && !cd.hasSetS("once", Const.INFINITE) )
			game.nextLevel();
	}
}
