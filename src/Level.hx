class Level extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;

	public var wid(get,never) : Int; inline function get_wid() return M.ceil(data.pxWid/Const.GRID);
	public var hei(get,never) : Int; inline function get_hei() return M.ceil(data.pxHei/Const.GRID);

	var invalidated = true;
	var data : ogmo.Level;

	public function new(l:ogmo.Level) {
		super(Game.ME);
		data = l;
		createRootInLayers(Game.ME.scroller, Const.DP_BG);
	}

	public inline function isValid(cx,cy) return cx>=0 && cx<wid && cy>=0 && cy<hei;
	public inline function coordId(cx,cy) return cx + cy*wid;


	public function render() {
		invalidated = false;
		root.removeChildren();

		var a = data.layers.copy();
		a.reverse();
		for(l in a) {
			if( l.type!=TileLayer )
				continue;
			l.render(root);
		}
		// Debug level render
		// for(cx in 0...wid)
		// for(cy in 0...hei) {
		// 	var g = new h2d.Graphics(root);
		// 	g.beginFill(Color.randomColor(rnd(0,1), 0.5, 0.4), 1);
		// 	g.drawRect(cx*Const.GRID, cy*Const.GRID, Const.GRID, Const.GRID);
		// }
	}

	override function postUpdate() {
		super.postUpdate();
		if( invalidated )
			render();
	}
}