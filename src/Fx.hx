import h2d.Sprite;
import dn.heaps.HParticle;
import dn.Tweenie;


class Fx extends dn.Process {
	public var pool : ParticlePool;

	public var bgAddSb    : h2d.SpriteBatch;
	public var bgNormalSb    : h2d.SpriteBatch;
	public var topAddSb       : h2d.SpriteBatch;
	public var topNormalSb    : h2d.SpriteBatch;

	var game(get,never) : Game; inline function get_game() return Game.ME;

	public function new() {
		super(Game.ME);

		pool = new ParticlePool(Assets.tiles.tile, 2048, Const.FPS);

		bgAddSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(bgAddSb, Const.DP_FX_BG);
		bgAddSb.blendMode = Add;
		bgAddSb.hasRotationScale = true;

		bgNormalSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(bgNormalSb, Const.DP_FX_BG);
		bgNormalSb.hasRotationScale = true;

		topNormalSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(topNormalSb, Const.DP_FX_TOP);
		topNormalSb.hasRotationScale = true;

		topAddSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(topAddSb, Const.DP_FX_TOP);
		topAddSb.blendMode = Add;
		topAddSb.hasRotationScale = true;
	}

	override public function onDispose() {
		super.onDispose();

		pool.dispose();
		bgAddSb.remove();
		bgNormalSb.remove();
		topAddSb.remove();
		topNormalSb.remove();
	}

	public function clear() {
		pool.killAll();
	}

	public inline function allocTopAdd(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(topAddSb, t, x, y);
	}

	public inline function allocTopNormal(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(topNormalSb, t,x,y);
	}

	public inline function allocBgAdd(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(bgAddSb, t,x,y);
	}

	public inline function allocBgNormal(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(bgNormalSb, t,x,y);
	}

	public inline function getTile(id:String) : h2d.Tile {
		return Assets.tiles.getTileRandom(id);
	}

	public function killAll() {
		pool.killAll();
	}

	public function markerEntity(e:Entity, ?c=0xFF00FF, ?short=false) {
		#if debug
		if( e==null )
			return;

		markerCase(e.cx, e.cy, short?0.03:3, c);
		#end
	}

	public function markerCase(cx:Int, cy:Int, ?sec=3.0, ?c=0xFF00FF) {
		#if debug
		var p = allocTopAdd(getTile("fxCircle"), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.lifeS = sec;

		var p = allocTopAdd(getTile("pixel"), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(2);
		p.lifeS = sec;
		#end
	}

	public function markerFree(x:Float, y:Float, ?sec=3.0, ?c=0xFF00FF) {
		#if debug
		var p = allocTopAdd(getTile("fxDot"), x,y);
		p.setCenterRatio(0.5,0.5);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(3);
		p.lifeS = sec;
		#end
	}

	public function markerText(cx:Int, cy:Int, txt:String, ?t=1.0) {
		#if debug
		var tf = new h2d.Text(Assets.fontTiny, topNormalSb);
		tf.text = txt;

		var p = allocTopAdd(getTile("fxCircle"), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.colorize(0x0080FF);
		p.alpha = 0.6;
		p.lifeS = 0.3;
		p.fadeOutSpeed = 0.4;
		p.onKill = tf.remove;

		tf.setPosition(p.x-tf.textWidth*0.5, p.y-tf.textHeight*0.5);
		#end
	}

	public function flashBangS(c:UInt, a:Float, ?t=0.1) {
		var e = new h2d.Bitmap(h2d.Tile.fromColor(c,1,1,a));
		game.scroller.add(e, Const.DP_FX_TOP);
		e.scaleX = game.w();
		e.scaleY = game.h();
		e.blendMode = Add;
		game.tw.createS(e.alpha, 0, t).end( function() {
			e.remove();
		});
	}

	public function emitSound(x:Float, y:Float, ?c=0xffffff) {
		var n = 2;
		for(i in 0...n) {
			var p = allocTopAdd(getTile("fxNova"), x,y);
			p.setFadeS(0.3, 0, 0.2);
			p.colorize(c);
			p.setScale(0.03);
			p.ds = 0.03;
			p.dsFrict = 0.83;
			p.delayS = 0.4*(i+1)/n;
			p.lifeS = 0.1;
		}
	}

	public function alarm(x:Float, y:Float) {
		var p = allocTopNormal(getTile("fxAlarm"), x,y);
		p.setCenterRatio(0.5,1);
		p.dy = -3;
		p.frict = 0.8;
		p.lifeS = 1;
	}

	public function question(x:Float, y:Float) {
		var p = allocTopNormal(getTile("fxQuestion"), x,y);
		p.setCenterRatio(0.5,1);
		p.dy = -1;
		p.frict = 0.8;
		p.lifeS = 1;
	}

	public function wallImpact(x:Float, y:Float, a:Float) {
		for(i in 0...15) {
			var a = a + M.PI + rnd(0,M.PIHALF,true);
			var p = allocTopAdd(getTile("fxLineDir"), x+rnd(0,6,true), y+rnd(0,6,true));
			p.setCenterRatio(1,0.5);
			p.colorAnimS(0xff9900, 0xff0000, rnd(0.2,0.4));
			p.moveAng(a, rnd(4,5));
			p.rotation = p.getMoveAng();
			p.scaleX = rnd(0.4,0.6);
			p.scaleXMul = rnd(0.92,0.97);
			p.frict = rnd(0.7,0.8);
			p.lifeS = rnd(0.2, 0.4);
		}
	}

	public function explosion(ox:Float, oy:Float, r:Float) {
		flashBangS(0xffcc00, 0.1, 0.7);
		// Bigs
		var n = 14;
		for(i in 0...n) {
			var dist = r*rnd(0.01,0.6);
			var a = rnd(0,6.28);
			var x = ox+Math.cos(a)*dist;
			var y = oy+Math.sin(a)*dist;
			var p = allocTopAdd(getTile("fxExplosion"), x,y);
			p.playAnimAndKill(Assets.tiles, "fxExplosion", rnd(0.7,0.8));
			p.rotation = rnd(0,6.28);
			p.setScale(rnd(0.7,1.1,true));
			p.delayS = i<=4 ? 0 : 0.25*i/n + rnd(0,0.03,true);
		}
		// Smokes
		var n = 20;
		for(i in 0...n) {
			var dist = r*rnd(0.2,0.7);
			var a = rnd(0,6.28);
			var x = ox+Math.cos(a)*dist;
			var y = oy+Math.sin(a)*dist;
			var p = allocBgNormal(getTile("fxExplosionSmoke"),x,y);
			p.alpha = rnd(0.6,0.8);
			p.playAnimAndKill(Assets.tiles, "fxExplosionSmoke", rnd(0.06,0.10));
			p.colorAnimS(0x660000, 0x0, rnd(0.4,0.8));
			p.rotation = rnd(0,6.28);
			p.setScale(rnd(0.8,1.1,true));
			p.delayS = 0.2*i/n + rnd(0,0.1,true);
		}
		// Lines
		for(i in 0...30) {
			var p = allocTopAdd(getTile("fxLineDir"), ox+rnd(0,20,true), oy+rnd(0,20,true));
			p.setCenterRatio(1,0.5);
			p.colorAnimS(0xffcc00, 0xff0000, rnd(0.2,0.4));
			p.moveAwayFrom(ox,oy, rnd(10,13));
			p.rotation = p.getMoveAng();
			p.scaleXMul = rnd(0.92,0.97);
			p.frict = rnd(0.7,0.8);
			p.lifeS = rnd(0.2, 0.4);
		}
	}

	public function destroyItem(e:Entity) {
		var n = 20;
		for(i in 0...n) {
			var a = 6.28*i/n + rnd(0,0.3,true);
			var p = allocTopNormal(getTile("fxFragment"), e.centerX+rnd(0,4,true), e.centerY+rnd(0,4,true));
			p.colorize(0x848ca5);
			p.moveAng(a, rnd(1.5,2));
			p.setFadeS(rnd(0.4,0.9), 0, rnd(0.1,0.2) );
			p.gy = rnd(0,0.02);
			p.frict = rnd(0.80,0.83);
			p.lifeS = rnd(1,1.5);
		}
	}

	public function pickPerma(e:Item, ?c=0x2b5997) {
		var n = 30;
		for(i in 0...n) {
			var a = 6.28*i/n + rnd(0,0.3,true);
			var p = allocTopAdd(getTile("pixel"), e.centerX+rnd(0,4,true), e.centerY+rnd(0,4,true));
			p.setFadeS(rnd(0.6,0.9), 0, rnd(0.3,0.7) );
			p.colorize(c);
			p.alphaFlicker = 0.5;
			p.dy = -rnd(1,3);
			p.gy = rnd(0.01, 0.02);
			// p.gy = -rnd(0.1,0.2);
			p.frict = rnd(0.87,0.91);
			p.lifeS = rnd(0.3,0.4);
		}
		var n = 30;
		for(i in 0...n) {
			var a = 6.28*i/n + rnd(0,0.3,true);
			var p = allocTopAdd(getTile("fxLineDir"), e.centerX+rnd(0,4,true), e.centerY+rnd(0,4,true));
			p.setCenterRatio(1,0.5);
			p.setFadeS(rnd(0.3,0.5), 0, rnd(0.5,0.7) );
			p.colorize(c);
			// p.colorize(Color.interpolateInt(0xffcc00, 0x990000, rnd(0,1)));
			p.moveAwayFrom(e.footX, e.footY+5, 0.1);
			p.rotation = p.getMoveAng();
			p.scaleX = -rnd(0.4,0.7);
			p.scaleY = rnd(2,3);
			p.scaleXMul = rnd(0.97,0.98);
			p.dr = rnd(0,0.01,true);
			p.frict = rnd(0.87,0.91);
			p.lifeS = rnd(0.3,0.4);
		}

		var n = 10;
		for(i in 0...n) {
			var a = 6.28*i/n + rnd(0,0.3,true);
			var p = allocTopAdd(getTile("fxSmoke"), e.footX+rnd(0,4,true), e.footY+rnd(0,4,true));
			p.setFadeS(rnd(0.2,0.3), 0, rnd(0.5,0.7) );
			p.colorize(c);
			p.rotation = rnd(0,6.28);
			p.moveAwayFrom(e.footX, e.footY, rnd(0.2,0.3));
			e.dy*=0.5;
			p.frict = 0.98;
			p.setScale(rnd(0.3,0.6,true));
			p.scaleXMul = rnd(1,1.01);
			p.dr = rnd(0,0.02,true);
			p.lifeS = rnd(1.3,1.4);
		}
	}

	public function openDoor(e:en.Door) {
		var n = 30;
		for(i in 0...n) {
			var p = allocTopNormal(getTile("fxFragment"), e.centerX+rnd(0,4,true), e.centerY+rnd(0,4,true));
			p.colorize(e.gold ? 0xffcc00 : 0x445577);
			p.dx = rnd(0, 1.5, true);
			p.dy = -rnd(1.5,3);
			p.rotation = rnd(0,6.28);
			p.setFadeS(rnd(0.4,0.9), 0, rnd(0.1,0.2) );
			p.gy = rnd(0.12,0.20);
			p.groundY = p.y+rnd(6,10);
			p.onBounce = function() {
				p.gy = p.dy = 0;
			}
			p.frict = rnd(0.80,0.83);
			p.lifeS = rnd(1,1.5);
		}
	}

	public function angle(x:Float, y:Float, ang:Float, dist:Float, ?sec=3.0, ?c=0xFF00FF) {
		#if debug
		var p = allocTopAdd(getTile("fxLineDir"), x,y);
		p.setCenterRatio(0,0.5);
		p.rotation = ang;
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.scaleX = dist/p.t.width;
		p.lifeS = sec;
		#end
	}

	function _bloodLand(p:HParticle) {
		p.gy = 0;
		p.dy = 0;
		p.scaleX = rnd(1,3);
	}

	public function hit(e:Entity, dir:Int) {
		var x = e.spr.x;
		var y = e.spr.y;
		for(i in 0...25) {
			var p = allocTopNormal(getTile("pixel"), x+rnd(0,1,true), y+rnd(0,1,true));
			p.colorize(0x791616);
			p.setFadeS(rnd(0.3,0.8), 0, rnd(0.1,0.3));
			p.dx = -dir*rnd(1,5);
			p.dy = -rnd(2, 2.5);
			p.frict = rnd(0.92, 0.96);
			p.gy = rnd(0.04,0.12);
			p.groundY = y+rnd(4,8);
			p.lifeS = rnd(0.3,1.2);
			p.onBounce = function() _bloodLand(p);
		}
		var p = allocBgNormal(getTile("fxSmoke"), x+rnd(0,2,true), y+rnd(0,2,true));
		p.setFadeS(rnd(0.3,0.5), 0, rnd(1,2));
		p.colorize(0x791616);
		p.rotation = rnd(0,6.28);
		p.setScale(rnd(0.2,0.3,true));
		p.scaleMul = rnd(0.97,0.99);
		p.dr = rnd(0,0.03,true);
		p.dy = -rnd(0.1,0.2);
		p.lifeS = rnd(0.3, 0.7);
		p.frict = 0.96;
	}

	public function bloodTail(e:Entity, dir:Int) {
		var x = e.spr.x;
		var y = e.spr.y;
		for(i in 0...15) {
			var p = allocBgNormal(getTile("pixel"), x+rnd(0,1,true), y+rnd(0,1,true));
			p.colorize(0x791616);
			p.setFadeS(rnd(0.3,0.8), 0, rnd(0.1,0.3));
			p.dx = dir*rnd(0.1,0.4);
			p.dy = -rnd(0.1, 0.2);
			p.frict = rnd(0.87, 0.96);
			p.gy = rnd(0.01,0.05);
			p.groundY = y+rnd(4,8);
			p.lifeS = rnd(0.3,1.2);
		}
		var p = allocBgNormal(getTile("fxSmoke"), x+rnd(0,2,true), y+rnd(0,2,true));
		p.setFadeS(rnd(0.3,0.5), 0, rnd(1,2));
		p.colorize(0x791616);
		p.rotation = rnd(0,6.28);
		p.setScale(rnd(0.2,0.3,true));
		p.scaleMul = rnd(0.97,0.99);
		p.dr = rnd(0,0.03,true);
		p.dy = -rnd(0.1,0.2);
		p.lifeS = rnd(0.3, 0.7);
		p.frict = 0.96;
	}

	public function bulletWall(x:Float, y:Float, ang:Float) {
		// Dots
		for(i in 0...15) {
			var p = allocTopAdd(getTile("pixel"), x+rnd(0,1,true), y+rnd(0,1,true));
			p.setFadeS(rnd(0.3,0.8), 0, rnd(0.1,0.3));
			p.moveAng(ang+M.PI+rnd(0,0.1,true), rnd(0.2,2));
			p.frict = rnd(0.87, 0.96);
			p.gy = rnd(0.01,0.05);
			p.colorize( Color.interpolateInt(0xffcc00,0xff0000,rnd(0,1)) );
			p.lifeS = rnd(0.3,0.6);
		}
		// Smoke
		for(i in 0...4) {
			var p = allocTopNormal(getTile("fxSmoke"), x+rnd(0,2,true), y+rnd(0,2,true));
			p.setFadeS(rnd(0.3,0.5), 0, rnd(1,2));
			p.colorize(0x772b2b);
			p.rotation = rnd(0,6.28);
			p.setScale(rnd(0.2,0.3,true));
			p.scaleMul = rnd(0.97,0.99);
			p.dr = rnd(0,0.03,true);
			p.dy = -rnd(0.1,0.2);
			p.frict = 0.96;
		}
	}

	public function bulletBleed(x:Float, y:Float, ang:Float) {
		// Dots
		for(i in 0...25) {
			var p = (i<=8 ? allocTopNormal : allocBgNormal)(getTile("pixel"), x+rnd(0,1,true), y+rnd(0,1,true));
			p.setFadeS(rnd(0.3,0.8), 0, rnd(0.1,0.3));
			p.moveAng(ang+M.PI+rnd(0,0.1,true), rnd(0.2,2));
			p.frict = rnd(0.87, 0.96);
			p.gy = rnd(0.01,0.05);
			p.colorize(0xaa0000);
			p.lifeS = rnd(0.3,0.6);
		}
		// Smoke
		for(i in 0...4) {
			var p = allocTopNormal(getTile("fxSmoke"), x+rnd(0,3,true), y+rnd(0,3,true));
			p.setFadeS(rnd(0.1,0.3), 0, rnd(0.3,0.6));
			p.colorize(0xcc0000);
			p.rotation = rnd(0,6.28);
			p.setScale(rnd(0.2,0.3,true));
			p.scaleMul = rnd(0.97,0.99);
			p.dr = rnd(0,0.03,true);
			p.dy = -rnd(0.1,0.2);
			p.frict = 0.96;
		}
	}

	public function shoot(x:Float, y:Float, ang:Float, c:UInt) {
		// Dots bullet
		for(i in 0...20) {
			var p = allocTopAdd(getTile("pixel"), x+rnd(0,1,true), y+rnd(0,1,true));
			p.setFadeS(rnd(0.6,0.9), 0, rnd(0.1,0.3));
			p.moveAng(ang+rnd(0,0.1,true), rnd(0.03,2));
			p.frict = rnd(0.94, 0.96);
			p.lifeS = rnd(0.1,0.2);
			p.colorize( Color.interpolateInt(0xffcc00,0xff7700,rnd(0,1)) );
		}
		// Dots source
		for(i in 0...25) {
			var p = allocTopAdd(getTile("pixel"), x+rnd(0,4,true), y+rnd(0,4,true));
			p.colorize(0x817da5);
			p.setFadeS(rnd(0.2,0.5), 0, rnd(0.1,0.3));
			p.moveAng(ang+rnd(0.1,0.3,true), rnd(0.03,2));
			// p.moveAwayFrom(x,y, rnd(0.05,0.3));
			p.frict = rnd(0.94, 0.96);
			p.lifeS = rnd(0.1,0.2);
		}
		// Line
		var p = allocTopAdd(getTile("fxLineDir"), x,y);
		p.colorize(c);
		p.rotation = ang;
		p.setFadeS(0.6, 0, 0.1);
		p.setCenterRatio(1,0.5);
		p.scaleX = -1;
		p.dsX = -0.1;
		p.dsFrict = 0.8;
		p.lifeS = 0.06;
		// Smoke
		// for(i in 0...4) {
		// 	var p = allocTopNormal(getTile("fxSmoke"), x+rnd(0,1,true), y+rnd(0,1,true));
		// 	p.setFadeS(rnd(0.1,0.2), 0, rnd(0.2,0.4));
		// 	p.colorize(c);
		// 	p.rotation = rnd(0,6.28);
		// 	p.setScale(rnd(0.2,0.4,true));
		// 	p.scaleMul = rnd(1,1.01);
		// 	p.dr = rnd(0,0.03,true);
		// 	p.dy = -rnd(0.1,0.2);
		// 	p.frict = 0.96;
		// }
	}

	public function throwAngle(x:Float, y:Float, ang:Float) {
		var p = allocTopAdd(getTile("fxLineDir"), x,y);
		p.setCenterRatio(1,0.5);
		p.rotation = ang;
		p.setFadeS(1, 0, 0.06);
		p.colorize(0x6d60c5);
		p.scaleX = -1;
		p.scaleY = 3;
		p.lifeS = 0;
	}

	public function viewCone(x:Float, y:Float, ang:Float, ?c=0x7a9aff) {
		var p = allocTopAdd(getTile("viewCone"), x,y);
		p.setCenterRatio(0,0.5);
		p.rotation = ang;
		p.setFadeS(0.2, 0, 0.06);
		p.colorize(c);
		p.setScale(0.25);
		p.lifeS = 0;
	}

	public function sweat(e:Entity) {
		var p = allocBgNormal(getTile("fxSweat"), e.headX-e.dir*2+rnd(0,1,true), e.headY+rnd(0,1,true));
		p.setFadeS(rnd(0.4,0.6), 0, 0.06);
		p.rotation = rnd(0,0.1,true);
		p.scaleX = e.dir;
		p.lifeS = rnd(0.06,0.15);
	}

	public function fire(x:Float, y:Float) {
		// var t = rnd(0.2,0.3);
		var p = allocBgNormal(getTile("fxSmoke"), x,y);
		p.colorize(0x440000);
		p.setFadeS(rnd(0.2,0.5), 0.2, 0.6);
		p.rotation = rnd(0,6.28);
		p.setScale(rnd(0.5,1.2,true));
		p.lifeS = 0.2;
		p.dy = -rnd(0.4,1);
		p.frict = rnd(0.92,0.94);

		for(i in 0...2) {
			var p = allocTopAdd(getTile("fxLargeFlame"), x+rnd(0,3,true), y+rnd(0,3,true));
			p.setCenterRatio(0.5, rnd(0.7,1));
			p.setFadeS(rnd(0.8,1), 0.2, 0.1);
			p.colorAnimS(0xffcc00, 0xc52424, rnd(0.3,0.4));
			p.scaleXMul = rnd(0.98,1.01);
			p.dsY = rnd(0.01,0.03);
			p.dsFrict = rnd(0.88,0.90);
			p.scaleX = rnd(0.6,0.9,true);
			p.scaleY = rnd(0.3,0.6);

			p.frict = rnd(0.92,0.94);
			p.lifeS = rnd(0.3,0.8);
			p.delayS = rnd(0,0.5);
		}
	}

	override function update() {
		super.update();

		pool.update(game.tmod);
	}
}