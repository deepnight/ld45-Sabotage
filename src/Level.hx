class Level extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;

	public var wid(get,never) : Int; inline function get_wid() return M.ceil(data.pxWid/Const.GRID);
	public var hei(get,never) : Int; inline function get_hei() return M.ceil(data.pxHei/Const.GRID);

	public var lid(get,never) : Int;
	var invalidatedColls = true;
	var invalidated = true;
	public var data : ogmo.Level;
	var layerRenders : Map<String,h2d.Object> = new Map();

	var damageMap : Map<Int, Float> = new Map();
	var collMap : Map<Int, Bool> = new Map();

	var roofBitmaps : Map<Int, h2d.Bitmap> = new Map();
	var texts : h2d.Object;
	public var pf : dn.PathFinder;

	public var specialEndingCondition = false;

	public function new(l:ogmo.Level) {
		super(Game.ME);
		data = l;

		for(cy in 0...hei)
		for(cx in 0...wid)
			collMap.set( coordId(cx,cy), data.getLayerByName("collisions").getIntGrid(cx,cy)>=1 );

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

	function get_lid() {
		var reg = ~/[A-Z\-_.]*([0-9]+)/gi;
		if( !reg.match(data.name) )
			return -1;
		else
			return Std.parseInt( reg.matched(1) );
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
		for(e in data.getLayerByName("entities").entities)
			if( e.name==id )
				return new CPoint(e.cx, e.cy);
		return null;
	}

	public function getEntityPts(id:String) {
		var a = [];
		for(e in data.getLayerByName("entities").entities)
			if( e.name==id )
				a.push( new CPoint(e.cx, e.cy) );
		return a;
	}

	public function getEntities(id:String) {
		var a = [];
		for(e in data.getLayerByName("entities").entities)
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
			var w = new h2d.Object(texts);
			if( e.getStr("bg")!="" ) {
				var bg = Assets.tiles.h_get(e.getStr("bg"),0, 0.5,0.5, w);
				bg.y = 2;
			}
			var tf = new h2d.Text(Assets.fontPixel, w);
			tf.text = e.getStr("str");
			tf.textColor = e.getColor("color");
			tf.x = Std.int( -tf.textWidth*0.5 );
			tf.y = Std.int( -tf.textHeight*0.5 );
			w.x = Std.int( e.x + Const.GRID*0.5 );
			w.y = Std.int( e.y + Const.GRID*0.5 );
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
				var tile = l.tileset.tile;
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
				var tile = l.tileset.tile;
				var tg = new h2d.TileGroup(tile, target);
				for(cy in 0...l.cHei)
				for(cx in 0...l.cWid) {
					if( !hasCollision(cx,cy) )
						continue;
					var cid = data.getLayerByName("collisions").getIntGrid(cx,cy);
					if( cid<=0 )
						continue;
					tg.add(
						cx*Const.GRID, cy*Const.GRID, tile.sub(
							(data.getLayerByName("collisions").getIntGrid(cx,cy+1)>0?1:0)*Const.GRID,
							(3+cid-1)*Const.GRID,
							Const.GRID, Const.GRID
						)
					);

					// Wall shadows
					if( cid!=5 && data.getLayerByName("collisions").getIntGrid(cx,cy+1)<=0 )
						tg.addAlpha( cx*Const.GRID, (cy+1)*Const.GRID, 0.3, tile.sub(irnd(3,5)*Const.GRID, 0, Const.GRID, Const.GRID) );
				}
			}

		}
	}

	public function hasRoof(cx,cy) return isValid(cx,cy) && data.getLayerByName("roofs").getTileId(cx,cy)>=0;
	// public inline function hasRoof(cx,cy) return isValid(cx,cy) && roofBitmaps.exists(coordId(cx,cy));
	public function hasVisibleRoof(cx,cy) return roofBitmaps.exists(coordId(cx,cy)) && getRoofBitmap(cx,cy).alpha>=0.9;
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

	var pBushes : h2d.Object;
	var pFog : h2d.Object;
	var pBack0: h2d.Object;
	var pBack1: h2d.Object;
	function updateParallax() {
		if( data.name!="intro2.json")
			return;

		if( pBushes==null ) {
			var baseCy = 9;

			pFog = new h2d.Object();
			game.scroller.add(pFog, Const.DP_TOP);
			for(i in 0...2) {
				var e = Assets.tiles.h_getRandom("forestFog", pFog);
				e.setCenterRatio(0,1);
				e.x = i*e.tile.width;
				e.y = Const.GRID*baseCy+6;
				e.alpha = 0.4;
				e.colorize( Color.hexToInt("#dbba84") );
			}

			pBushes = new h2d.Object();
			game.scroller.add(pBushes, Const.DP_TOP);
			for(i in 0...3) {
				var e = Assets.tiles.h_getRandom("forestBushes", pBushes);
				e.setCenterRatio(0,1);
				e.x = i*e.tile.width;
				e.y = Const.GRID*baseCy+6;
				e.colorize(0x0);
			}

			pBack1 = new h2d.Object();
			game.scroller.add(pBack1, Const.DP_BG);
			pBack1.scale(0.75);
			for(i in 0...2) {
				var e = Assets.tiles.h_getRandom("forestBg", pBack1);
				e.setCenterRatio(0,1);
				e.x = i*e.tile.width;
				e.y = Const.GRID*baseCy+30;
				e.colorize( Color.hexToInt("#322745") );
			}

			pBack0 = new h2d.Object();
			game.scroller.add(pBack0, Const.DP_BG);
			for(i in 0...2) {
				var e = Assets.tiles.h_getRandom("forestBg", pBack0);
				e.setCenterRatio(0,1);
				e.x = i*e.tile.width;
				e.y = Const.GRID*baseCy;
				e.colorize( Color.hexToInt("#242b31") );
			}

		}
		// pBushes.x = -game.scroller.x*0.3;
		pFog.x = -game.scroller.x*0.2;
		pBack0.x = -game.scroller.x*0.3-40;
		pBack1.x = -game.scroller.x*0.5-50;
	}


	override function postUpdate() {
		super.postUpdate();

		updateParallax();

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