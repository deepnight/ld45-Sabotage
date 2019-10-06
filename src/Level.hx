class Level extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;

	public var wid(get,never) : Int; inline function get_wid() return M.ceil(data.pxWid/Const.GRID);
	public var hei(get,never) : Int; inline function get_hei() return M.ceil(data.pxHei/Const.GRID);

	public var lid : Int;
	var invalidatedColls = true;
	var invalidated = true;
	var data : ogmo.Level;
	var layerRenders : Map<String,h2d.Object> = new Map();

	var damageMap : Map<Int, Float> = new Map();
	var collMap : Map<Int, Bool> = new Map();

	var roofBitmaps : Map<Int, h2d.Bitmap> = new Map();
	var texts : h2d.Object;
	public var pf : dn.PathFinder;

	public var noMobs = false;

	public function new(lid:Int, l:ogmo.Level) {
		super(Game.ME);
		this.lid = lid;
		data = l;

		for(cy in 0...hei)
		for(cx in 0...wid)
			collMap.set( coordId(cx,cy), data.layersByName.get("collisions").getIntGrid(cx,cy)>=1 );

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

		texts = new h2d.Object();
		game.scroller.add(texts, Const.DP_BG);

		pf = new dn.PathFinder(wid, hei);
	}

	override function onDispose() {
		super.onDispose();
		for(l in layerRenders)
			l.remove();
		for(e in roofBitmaps)
			e.remove();
		texts.remove();
		data = null;
		pf.destroy();
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

	public function setCollision(cx,cy,v ) {
		if( isValid(cx,cy) ) {
			invalidatedColls = true;
			collMap.set( coordId(cx,cy), v );
		}
	}

	public function hasCollision(cx,cy) {
		return isValid(cx,cy) ? collMap.get(coordId(cx,cy))==true : true;
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
		texts.removeChildren();

		for(e in getEntities("text")) {
			var tf = new h2d.Text(Assets.fontPixel, texts);
			tf.text = e.getStr("str");
			tf.textColor = e.getColor("color");
			tf.x = Std.int( e.x + Const.GRID*0.5 - tf.textWidth*0.5 );
			tf.y = Std.int( e.y + Const.GRID*0.5 - tf.textHeight*0.5 );

		}

		for(l in data.layersReversed) {
			var target = layerRenders.get(l.name);
			// if( l.name=="roofs" ) {
			// 	// Special roof render
			// 	for(cy in 0...l.cHei)
			// 	for(cx in 0...l.cWid) {
			// 		if( l.getTileId(cx,cy)<0 )
			// 			continue;

			// 		var b = new h2d.Bitmap(l.tileset.getTile( l.getTileId(cx,cy) ), target);
			// 		b.setPosition(cx*l.gridWid, cy*l.gridHei);
			// 		roofBitmaps.set( coordId(cx,cy), b );
			// 	}
			// 	target.y-=8;

			// 	continue;
			// }

			// Auto render roofs
			if( l.name=="roofs" ) {
				var tile = l.tileset.t;
				for(cy in 0...l.cHei)
				for(cx in 0...l.cWid) {
					if( l.getTileId(cx,cy)<0 )
						continue;
					var tx = 0;
					var ty = 0;
					if( l.getTileId(cx-1,cy)<0 && l.getTileId(cx,cy-1)<0 ) ty = 0;
					else if( l.getTileId(cx-1,cy)<0 && l.getTileId(cx,cy+1)<0 ) ty = 2;
					else if( l.getTileId(cx+1,cy)<0 && l.getTileId(cx,cy-1)<0 ) tx = 2;
					else if( l.getTileId(cx+1,cy)<0 && l.getTileId(cx,cy+1)<0 ) { tx = 2; ty = 2; }
					else if( l.getTileId(cx-1,cy)<0 ) { ty = 1; }
					else if( l.getTileId(cx+1,cy)<0 ) { tx = 2; ty = 1; }
					else if( l.getTileId(cx,cy-1)<0 ) { tx = 1; }
					else if( l.getTileId(cx,cy+1)<0 ) { tx = 1; ty = 2; }
					else { tx = ty = 1; }
					var b = new h2d.Bitmap( tile.sub( tx*Const.GRID, ty*Const.GRID, Const.GRID, Const.GRID ), target );
					b.setPosition(cx*l.gridWid, cy*l.gridHei-8);
					roofBitmaps.set( coordId(cx,cy), b );
				}
				continue;
			}

			// Default renders
			switch l.type {
				case TileLayer: l.render(target, l.name=="add" ? h2d.BlendMode.Add : h2d.BlendMode.Alpha);
				// case EntityLayer: #if debug l.render(target, 0.5); #end
				// case IntGridLayer: #if debug l.render(target, 0.5); #end
				case _:
			}

			// Auto render collisions (time saving!)
			if( l.name=="ground" ) {
				var tile = l.tileset.t;
				var tg = new h2d.TileGroup(tile, target);
				for(cy in 0...l.cHei)
				for(cx in 0...l.cWid) {
					if( !hasCollision(cx,cy) )
						continue;
					var cid = data.layersByName.get("collisions").getIntGrid(cx,cy);
					if( cid<=0 )
						continue;
					tg.add(
						cx*Const.GRID, cy*Const.GRID, tile.sub(
							(data.layersByName.get("collisions").getIntGrid(cx,cy+1)>0?1:0)*Const.GRID,
							(3+cid-1)*Const.GRID,
							Const.GRID, Const.GRID
						)
					);

					// Wall shadows
					if( data.layersByName.get("collisions").getIntGrid(cx,cy+1)<=0 )
						tg.addAlpha( cx*Const.GRID, (cy+1)*Const.GRID, 0.3, tile.sub(irnd(3,5)*Const.GRID, 0, Const.GRID, Const.GRID) );
				}
			}

		}
	}

	public function hasRoof(cx,cy) return isValid(cx,cy) && data.layersByName.get("roofs").getTileId(cx,cy)>=0;
	// public inline function hasRoof(cx,cy) return isValid(cx,cy) && roofBitmaps.exists(coordId(cx,cy));
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

	function onCollisionChange() {
		invalidatedColls = false;

		pf.fillAll(false);
		pf.resetCache();
		for(cy in 0...hei)
		for(cx in 0...wid)
			pf.setCollision(cx,cy, hasCollision(cx,cy));
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) render();
		if( invalidatedColls ) onCollisionChange();

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
					b.alpha += (0-b.alpha)*0.4;
					if( b.alpha<=0.4 ) {
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