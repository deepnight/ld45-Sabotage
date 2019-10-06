package en;

class Door extends Entity {
	public static var ALL : Array<Door> = [];

	var isOpen = false;

	public function new(x,y) {
		super(x,y);
		yr = 1;
		ALL.push(this);
		hasCollisions = false;

		spr.set(level.hasCollision(cx,cy+1) ? "doorV" : "doorH");
		updateCollisions();
		disableShadow();
	}

	function updateCollisions() {
		if( level!=null && !level.destroyed )
			level.setCollision(cx,cy, !isOpen);
	}

	public function open() {
		isOpen = true;
		updateCollisions();
	}

	override function dispose() {
		super.dispose();
		isOpen = true;
		updateCollisions();
	}

	override function update() {
		cancelVelocities();
		super.update();
	}
}
