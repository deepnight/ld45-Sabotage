import dn.Process;
import hxd.Key;

class Game extends Process {
	public static var ME : Game;

	public var ca : ControllerAccess;
	public var fx : Fx;
	public var camera : Camera;
	public var scroller : h2d.Layers;
	public var level : Level;
	public var hud : ui.Hud;

	public var hero : en.Hero;

	public function new() {
		super(Main.ME);
		ME = this;
		ca = Main.ME.controller.createAccess("game");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);
		createRootInLayers(Main.ME.root, Const.DP_BG);

		scroller = new h2d.Layers();
		root.add(scroller, Const.DP_BG);

		camera = new Camera();
		fx = new Fx();
		hud = new ui.Hud();

		startLevel("intro");
	}

	public function nextLevel() {
		if( level.data.getStr("nextLevel")!="" )
			startLevel(level.data.getStr("nextLevel"));
		else {
			var ogmoProj = new ogmo.Project(hxd.Res.map.ld45_ogmo, false);
			if( ogmoProj.getLevelByName("level"+(level.lid+1))==null )
				startLevel("level"+level.lid);
			else
				startLevel("level"+(level.lid+1));
		}
	}

	public function restartLevel() {
		startLevel(level.data.name);
	}

	public function startLevel(name:String) {
		var mask = new h2d.Bitmap(h2d.Tile.fromColor(0x0));
		root.add(mask, Const.DP_MASK);
		mask.scaleX = M.ceil( w()/Const.SCALE );
		mask.scaleY = M.ceil( h()/Const.SCALE );
		tw.createS(mask.alpha, 0, 0.5).end( mask.remove );

		if( level!=null ) {
			level.destroy();
			for(e in Entity.ALL)
				e.destroy();
			gc();
			fx.clear();
		}

		var ogmoProj = new ogmo.Project(hxd.Res.map.ld45_ogmo, false);
		var data = ogmoProj.getLevelByName(name);
		level = new Level(data);

		var pt = level.getEntityPt("hero");
		hero = new en.Hero(pt.cx, pt.cy);
		camera.target = hero;
		camera.recenter();

		for(e in level.getEntities("exit")) new en.Exit(e.cx, e.cy);
		for(e in level.getEntities("door")) new en.Door(e.cx, e.cy, e.getStr("color")=="gold");
		for(e in level.getEntities("turret")) new en.mob.Turret(e);
		for(e in level.getEntities("guard")) new en.mob.Guard(e);
		for(e in level.getEntities("item")) new en.Item(e.cx, e.cy, e.getEnum("type",ItemType));
		for(e in level.getEntities("spikes")) new en.Spike(e.cx, e.cy, false);
		for(e in level.getEntities("spikesFragile")) new en.Spike(e.cx, e.cy, true);

		if( en.Mob.ALL.length==0 )
			level.specialEndingCondition = true;

		if( level.lid>=0 )
			bigText("Level "+(level.lid+1));
		cd.unset("levelDone");
		hud.invalidate();
	}

	public function onCdbReload() {
	}

	public function bigText(str:Dynamic, ?c=0xffcc00) {
		var tf = new h2d.Text(Assets.fontLarge);
		root.add(tf, Const.DP_UI);
		tf.blendMode = Add;
		tf.text = Std.string(str);
		tf.textColor = c;
		tf.x = Std.int( w()/Const.SCALE*0.5- tf.textWidth*0.5 );
		tf.y = Std.int( h()/Const.SCALE*0.5- tf.textHeight*0.5 );
		tw.createS(tf.alpha, 0>1, 0.1).end( function() {
			tw.createS(tf.alpha, 500|0, 1).end( tf.remove );
		});
	}


	function gc() {
		if( Entity.GC==null || Entity.GC.length==0 )
			return;

		for(e in Entity.GC)
			e.dispose();
		Entity.GC = [];
	}

	override function onDispose() {
		super.onDispose();

		fx.destroy();
		for(e in Entity.ALL)
			e.destroy();
		gc();
	}

	override function update() {
		super.update();

		// Updates
		for(e in Entity.ALL) if( !e.destroyed ) e.preUpdate();
		for(e in Entity.ALL) if( !e.destroyed ) e.update();
		Entity.ALL.sort( function(a,b) return Reflect.compare(a.footY+a.sprOffY+a.zPriorityOffset, b.footY+b.sprOffY+b.zPriorityOffset)); // Z-sort
		for(e in Entity.ALL) if( !e.destroyed ) {
			e.zOver();
			e.postUpdate();
		}
		for(e in Entity.ALL) if( !e.destroyed ) e.frameEnd();
		gc();

		// Victory check
		if( !level.specialEndingCondition ) {
			var any = false;
			for(e in Mob.ALL)
				if( e.isAlive() ) {
					any = true;
					break;
				}
			if( !any && !cd.hasSetS("levelDone",Const.INFINITE) ) {
				cd.setS("autoNext", 2);
				bigText("Mission complete", 0xff0000);
			}
			if( cd.has("levelDone") && !cd.has("autoNext") ) {
				var mask = new h2d.Bitmap(h2d.Tile.fromColor(0x0));
				cd.setS("autoNext",2);
				root.add(mask, Const.DP_MASK);
				mask.scaleX = M.ceil( w()/Const.SCALE );
				mask.scaleY = M.ceil( h()/Const.SCALE );
				tw.createS(mask.alpha, 0>1, 0.5).end( function() {
					mask.remove();
					nextLevel();
				} );
			}

		}

		if( !ui.Console.ME.isActive() && !ui.Modal.hasAny() ) {
			// Exit
			if( ca.isKeyboardPressed(Key.X) )
				if( !cd.hasSetS("exitWarn",3) )
					trace(Lang.t._("Press X again to exit."));
				else {
					#if( debug && hl )
					hxd.System.exit();
					#else
					destroy();
					new Title();
					#end
				}

			if( ca.selectPressed() )
				restartLevel();

			// Kid mode
			if( ca.isKeyboardPressed(Key.K ) ) {
				if( cd.has("kidMode") )
					cd.unset("kidMode");
				else
					cd.setS("kidMode", Const.INFINITE);
				bigText("Kid mode: "+(cd.has("kidMode")?"ON":"off"));
			}

			#if debug
			// Debug
			if( ca.isKeyboardPressed(Key.N) )
				nextLevel();

			// if( ca.isKeyboardPressed(Key.K) )
			// 	for(e in Mob.ALL) e.hit(999);

			if( ca.isKeyboardPressed(Key.G) )
				Main.ME.startGame();

			if( ca.isKeyboardPressed(Key.T) )
				startLevel("test");
			#end
		}
	}
}

