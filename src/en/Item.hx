package en;

class Item extends Entity {
	public static var ALL : Array<Item> = [];
	var item : ItemType;
	public function new(x,y,i:ItemType) {
		super(x,y);
		ALL.push(this);
		item = i;
		spr.set( switch item {
			case Barrel: "barrel";
		});
	}

	public function isGrabbed() return hero.item==this;

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}
}