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

	public function hasCollision(cx,cy) {
		return isValid(cx,cy) ? data.layersByName.get("collisions").getIntGrid(cx,cy)==1 : true;
	}


	public function getEntityPt(id:String) {
		for(e in data.layersByName.get("entities").entities)
			if( e.name==id )
				return new CPoint(e.cx, e.cy);
		return null;
	}

	public function render() {
		invalidated = false;
		root.removeChildren();

		for(l in data.layersReversed) {
			switch l.type {
				case TileLayer: l.render(root);
				case EntityLayer: #if debug l.render(root, 0.5); #end
				case IntGridLayer: #if debug l.render(root, 0.5); #end
			}
		}

		// for(cx in 0...wid)
		// for(cy in 0...hei)
		// 	if( hasCollision(cx,cy) ) {
		// 		var g = new h2d.Graphics(root);
		// 		g.lineStyle(1, 0xffffff, 1);
		// 		g.drawCircle((cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID, Const.GRID*0.5);
		// 	}
	}

	override function postUpdate() {
		super.postUpdate();
		if( invalidated )
			render();
	}
}