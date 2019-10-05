class Level extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;

	public var wid(get,never) : Int; inline function get_wid() return M.ceil(data.pxWid/Const.GRID);
	public var hei(get,never) : Int; inline function get_hei() return M.ceil(data.pxHei/Const.GRID);

	var invalidated = true;
	var data : ogmo.Level;
	var layerRenders : Map<String,h2d.Object> = new Map();

	var damageMap : Map<Int, Float> = new Map();

	var roofBitmaps : Map<Int, h2d.Bitmap> = new Map();
	public var pf : dn.PathFinder;

	public function new(l:ogmo.Level) {
		super(Game.ME);
		data = l;
		createRootInLayers(game.scroller, Const.DP_BG);

		for(l in data.layersReversed) {
			var o = new h2d.Object();
			game.scroller.add(o, switch l.name {
				case "roofs" : Const.DP_TOP;
				case _ : Const.DP_BG;
			});

			switch l.name {
				case _ : layerRenders.set(l.name, o);
			}
		}

		pf = new dn.PathFinder(wid, hei);
		for(cy in 0...hei)
		for(cx in 0...wid)
			pf.setCollision(cx,cy, hasCollision(cx,cy));
	}

	public inline function getDamage(cx,cy) {
		return isValid(cx,cy) && damageMap.exists(coordId(cx,cy)) ? damageMap.get(coordId(cx,cy)) : 0.;
	}

	public inline function damage(cx,cy, pow:Float) {
		if( !isValid(cx,cy) || getDamage(cx,cy)>=1 )
			return;

		damageMap.set( coordId(cx,cy), M.fclamp(getDamage(cx,cy)+pow, 0, 1) );
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

	public function getEntityPts(id:String) {
		var a = [];
		for(e in data.layersByName.get("entities").entities)
			if( e.name==id )
				a.push( new CPoint(e.cx, e.cy) );
		return a;
	}

	public function getEntities(id:String) {
		var a = [];
		for(e in data.layersByName.get("entities").entities)
			if( e.name==id )
				a.push(e);
		return a;
	}

	public function render() {
		invalidated = false;
		for(e in layerRenders)
			e.removeChildren();
		roofBitmaps = new Map();

		for(l in data.layersReversed) {
			var target = layerRenders.get(l.name);
			if( l.name=="roofs" ) {
				// Special roof render
				for(cy in 0...l.cHei)
				for(cx in 0...l.cWid) {
					if( l.getTileId(cx,cy)<0 )
						continue;

					var b = new h2d.Bitmap(l.tileset.getTile( l.getTileId(cx,cy) ), target);
					b.setPosition(cx*l.gridWid, cy*l.gridHei);
					roofBitmaps.set( coordId(cx,cy), b );
				}
				target.y-=8;

				continue;
			}

			// Default renders
			switch l.type {
				case TileLayer: l.render(target);
				// case EntityLayer: #if debug l.render(target, 0.5); #end
				// case IntGridLayer: #if debug l.render(target, 0.5); #end
				case _:
			}
		}
	}

	public inline function hasRoof(cx,cy) return isValid(cx,cy) && roofBitmaps.exists(coordId(cx,cy));
	public inline function hasVisibleRoof(cx,cy) return hasRoof(cx,cy) && getRoofBitmap(cx,cy).alpha>=0.9;
	inline function getRoofBitmap(cx,cy) : Null<h2d.Bitmap> return hasRoof(cx,cy) ? roofBitmaps.get(coordId(cx,cy)) : null;
	var roofEraseMarks : Map<Int,Bool> = new Map();
	public inline function eraseRoofFrom(cx,cy) {
		if( hasRoof(cx,cy) )
			roofEraseMarks.set( coordId(cx,cy), true );
	}

	public inline function clearRoofErase() {
		roofEraseMarks = new Map();
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) render();

		for(cy in 0...hei)
		for(cx in 0...wid) {
			if( !cd.has("fireFx") && getDamage(cx,cy)>0 && ( hasCollision(cx,cy) || hasRoof(cx,cy) && hasVisibleRoof(cx,cy) ) )
				fx.fire((cx+rnd(0.3,0.7))*Const.GRID, (cy+rnd(0.2,1))*Const.GRID);

			// Roof anim
			if( hasRoof(cx,cy) ) {
				var b = getRoofBitmap(cx,cy);
				if( !roofEraseMarks.exists(coordId(cx,cy)) && b.alpha<1 )
					b.alpha += (1-b.alpha)*0.1;
				if( roofEraseMarks.exists(coordId(cx,cy)) && b.alpha>0 ) {
					b.alpha += (0-b.alpha)*0.3;
					if( b.alpha<=0.2 ) {
						eraseRoofFrom(cx-1,cy);
						eraseRoofFrom(cx+1,cy);
						eraseRoofFrom(cx,cy-1);
						eraseRoofFrom(cx,cy+1);
					}
				}
			}
		}
		cd.hasSetS("fireFx",0.15);
	}
}