import dn.Process;
import hxd.Key;

class Game extends Process {
	public static var ME : Game;

	public var ca : dn.heaps.Controller.ControllerAccess;
	public var fx : Fx;
	public var camera : Camera;
	public var scroller : h2d.Layers;
	public var ogmoProj : ogmo.Project;
	public var level : Level;

	public var hero : en.Hero;

	public function new() {
		super(Main.ME);
		ME = this;
		ca = Main.ME.controller.createAccess("game");
		ca.leftDeadZone = 0.2;
		ca.rightDeadZone = 0.2;
		createRootInLayers(Main.ME.root, Const.DP_BG);

		scroller = new h2d.Layers();
		if( Const.SCALE>1 )
			scroller.filter = new h2d.filter.ColorMatrix(); // force pixel render
		root.add(scroller, Const.DP_BG);

		camera = new Camera();
		fx = new Fx();

		startLevel(0);
	}


	public function startLevel(id:Int) {
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

		ogmoProj = new ogmo.Project(hxd.Res.map.ld45, false);
		var data = ogmoProj.getLevelName("level"+id);
		while( data==null ) {
			id--;
			data = ogmoProj.getLevelName("level"+id);
		}
		level = new Level(id, data);

		var pt = level.getEntityPt("hero");
		hero = new en.Hero(pt.cx, pt.cy);
		camera.target = hero;
		camera.recenter();

		for(e in level.getEntities("door")) new en.Door(e.cx, e.cy, e.getStr("color")=="gold");
		for(e in level.getEntities("guard")) new en.Mob(e.cx, e.cy, e);
		for(e in level.getEntities("item")) new en.Item(e.cx, e.cy, e.getEnum("type",ItemType));
		for(e in level.getEntities("spikes")) new en.Spike(e.cx, e.cy);

		bigText("Level "+(id+1));
		cd.unset("levelDone");
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
		gc();

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
		if( cd.has("levelDone") && !cd.has("autoNext") )
			startLevel(level.lid+1);

		if( !ui.Console.ME.isActive() && !ui.Modal.hasAny() ) {
			#if hl
			// Exit
			if( ca.isKeyboardPressed(Key.ESCAPE) )
				if( !cd.hasSetS("exitWarn",3) )
					trace(Lang.t._("Press ESCAPE again to exit."));
				else
					hxd.System.exit();
			#end

			#if debug
			if( ca.isKeyboardPressed(Key.R) )
				startLevel(level.lid);
			if( ca.isKeyboardPressed(Key.K) )
				for(e in Mob.ALL) e.hit(999);
			#end
		}
	}
}

