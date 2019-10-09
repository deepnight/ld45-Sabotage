package ui;

class Hud extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;
	public var level(get,never) : Level; inline function get_level() return Game.ME.level;

	var flow : h2d.Flow;
	var invalidated = true;

	public function new() {
		super(Game.ME);

		createRootInLayers(game.root, Const.DP_UI);

		flow = new h2d.Flow(root);
		flow.horizontalSpacing = 0;
		flow.blendMode = Add;
		flow.verticalAlign = Middle;
		flow.y = -5;
	}

	override function onDispose() {
		super.onDispose();
	}

	public inline function invalidate() invalidated = true;

	function render() {
		flow.removeChildren();
		if( game.hero.hasPermaItem(GoldKey) ) Assets.tiles.h_get("GoldKey", flow);
		if( game.hero.hasPermaItem(SilverKey) ) Assets.tiles.h_get("SilverKey", flow);
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}
