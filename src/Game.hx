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
		ogmoProj = new ogmo.Project(hxd.Res.map.ld45, false);
		level = new Level(ogmoProj.levels[0]);
		fx = new Fx();

		var pt = level.getEntityPt("hero");
		hero = new en.Hero(pt.cx, pt.cy);
		camera.target = hero;
		camera.recenter();

		for(e in level.getEntities("guard"))
			new en.Mob(e.cx, e.cy, e);

		for(e in level.getEntities("item"))
			new en.Item(e.cx, e.cy, e.getEnum("type",ItemType));

		for(e in level.getEntities("door"))
			new en.Door(e.cx, e.cy);
	}

	public function onCdbReload() {
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
				Main.ME.startGame();
			#end
		}
	}
}

